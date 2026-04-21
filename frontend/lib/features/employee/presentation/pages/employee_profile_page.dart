import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/services/auth_service.dart';
import '../widgets/employee_header.dart';
import '../widgets/employee_notifications_drawer.dart';

class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;

  // Controllers para datos personales
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _idController;
  late TextEditingController _salaryController;
  late TextEditingController _addressController;
  late TextEditingController _bankController;
  late TextEditingController _accountController;
  late TextEditingController _companyController;

  // Empresa seleccionada
  int? _selectedCompanyId;
  List<Map<String, dynamic>> _availableCompanies = [];
  bool _loadingCompanies = false;

  // Controllers para seguridad
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Refrescar perfil al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
    // Cargar empresas disponibles
    _loadAvailableCompanies();
  }

  Future<void> _loadAvailableCompanies() async {
    setState(() => _loadingCompanies = true);
    try {
      final response = await apiService.get('/api/companies/available/');
      setState(() {
        _availableCompanies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Mostrar error en consola para depuración
      debugPrint('Error cargando empresas: $e');
    } finally {
      setState(() => _loadingCompanies = false);
    }
  }
  
  String _formatCurrency(double value) {
    String result = value.toStringAsFixed(0);
    result = result.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return result;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _companyController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        // Inicializar controllers con datos del usuario
        _nameController = TextEditingController(
          text: user?.firstName != null && user?.lastName != null
              ? '${user?.firstName} ${user?.lastName}'
              : user?.firstName ?? user?.username ?? 'Usuario',
        );
        _emailController = TextEditingController(text: user?.email ?? '');
        _idController = TextEditingController(text: user?.documentNumber ?? '');
        _salaryController = TextEditingController(
          text: '\$ ${_formatCurrency(user?.employeeProfile?.salary ?? 0.0)}',
        );
        _addressController = TextEditingController(text: 'No especificada');
        _bankController = TextEditingController(
          text: user?.employeeProfile?.bankName?.isNotEmpty == true
              ? user!.employeeProfile!.bankName!
              : 'No especificado',
        );
        _accountController = TextEditingController(
          text: user?.employeeProfile?.bankAccount?.isNotEmpty == true
              ? user!.employeeProfile!.bankAccount!
              : 'No especificada',
        );
        _selectedCompanyId = user?.employeeProfile?.companyId;
        _companyController = TextEditingController(
          text: user?.employeeProfile?.companyName?.isNotEmpty == true
              ? user!.employeeProfile!.companyName!
              : 'No especificada',
        );
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          endDrawer: const EmployeeNotificationsDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                const EmployeeHeader(),

                // TabBar
                _buildTabBar(),

                // Contenido
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPersonalDataTab(user),
                      _buildSecurityTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pop(context);
            },
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text(
              'Volver',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Datos Personales'),
            Tab(text: 'Seguridad'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDataTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de información personal
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del card
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actualiza tus datos de contacto',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón Editar/Guardar
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isEditing) {
                          _saveProfile();
                        } else {
                          setState(() {
                            _isEditing = true;
                          });
                        }
                      },
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        size: 16,
                      ),
                      label: Text(_isEditing ? 'Guardar' : 'Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Campos del formulario
                _buildFormField(
                  icon: Icons.person_outline,
                  label: 'Nombre completo',
                  controller: _nameController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  controller: _emailController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  icon: Icons.badge_outlined,
                  label: 'Cédula',
                  controller: _idController,
                  enabled: false,
                  helperText: 'La cédula no se puede modificar',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  icon: Icons.attach_money,
                  label: 'Salario',
                  controller: _salaryController,
                  enabled: false,
                  helperText: 'Contacta a tu empleador para modificar tu salario',
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  controller: _addressController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 16),
                // Campo de empresa
                _isEditing 
                  ? _buildCompanyDropdown()
                  : _buildFormField(
                      icon: Icons.business_outlined,
                      label: 'Empresa',
                      controller: _companyController,
                      enabled: false,
                    ),
                const SizedBox(height: 16),
                _buildBankDropdown(
                  context: context,
                  value: _bankController.text,
                  enabled: _isEditing,
                  onChanged: (value) {
                    setState(() {
                      _bankController.text = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  icon: Icons.credit_card_outlined,
                  label: 'Número de cuenta',
                  controller: _accountController,
                  enabled: _isEditing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Información importante:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Mantén tu información actualizada para recibir tus adelantos'),
                _buildBulletPoint('Verifica que tu número de cuenta esté correcto'),
                _buildBulletPoint('Los cambios en salario deben ser realizados por tu empleador'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de cambiar contraseña
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cambiar Contraseña',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actualiza tu contraseña de acceso',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 24),
                // Campo contraseña actual
                _buildPasswordField(
                  label: 'Contraseña actual',
                  controller: _currentPassController,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 16),
                // Campo nueva contraseña
                _buildPasswordField(
                  label: 'Nueva contraseña',
                  controller: _newPassController,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 16),
                // Campo confirmar contraseña
                _buildPasswordField(
                  label: 'Confirmar nueva contraseña',
                  controller: _confirmPassController,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 16),
                // Info box amarillo
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFBD4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEF08A), width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: const Color(0xFFA16207),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Requisitos de contraseña:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Mínimo 6 caracteres', color: const Color(0xFFA16207)),
                      _buildBulletPoint('Se recomienda usar letras, números y símbolos', color: const Color(0xFFA16207)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Botón actualizar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updatePassword(context),
                    icon: const Icon(Icons.key, size: 18),
                    label: const Text(
                      'Actualizar Contraseña',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info box seguridad
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: const Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Seguridad de tu cuenta:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Cambia tu contraseña regularmente', color: const Color(0xFF1E40AF)),
                _buildBulletPoint('No compartas tu contraseña con nadie', color: const Color(0xFF1E40AF)),
                _buildBulletPoint('Usa una contraseña única para esta plataforma', color: const Color(0xFF1E40AF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? const Color(0xFF111827) : Colors.grey[500],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  // Lista de bancos disponibles
  final List<String> _banks = [
    'Bancolombia',
    'Banco de Bogotá',
    'Davivienda',
    'BBVA Colombia',
    'Citibank',
    'Itaú',
    'Scotiabank Colpatria',
    'Banco Popular',
    'Banco de Occidente',
    'Banco Caja Social',
    'Banco Agrario',
    'Nequi (Bancolombia)',
    'Daviplata',
    'Movii',
    'Otro',
  ];

  Widget _buildBankDropdown({
    required BuildContext context,
    required String value,
    required bool enabled,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            const Text(
              'Banco',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: enabled
              ? () => _showBankSelector(context, value, onChanged)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: enabled
                  ? Border.all(color: const Color(0xFFE5E7EB))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value == 'No especificado' ? 'Seleccionar banco...' : value,
                  style: TextStyle(
                    color: value == 'No especificado'
                        ? Colors.grey[500]
                        : enabled
                            ? const Color(0xFF111827)
                            : Colors.grey[500],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? const Color(0xFF6B7280) : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyDropdown() {
    if (_loadingCompanies) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_availableCompanies.isEmpty) {
      return _buildFormField(
        icon: Icons.business_outlined,
        label: 'Empresa',
        controller: _companyController,
        enabled: false,
      );
    }

    // Encontrar el nombre de la empresa seleccionada
    final selectedCompany = _availableCompanies.firstWhere(
      (c) => c['id'] == _selectedCompanyId,
      orElse: () => {'name': 'Seleccionar empresa...'},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business_outlined, size: 18, color: Color(0xFF6B7280)),
            const SizedBox(width: 8),
            const Text(
              'Empresa',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showCompanySelector(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCompany['name'] ?? 'Seleccionar empresa...',
                  style: const TextStyle(color: Color(0xFF111827)),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCompanySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seleccionar empresa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableCompanies.length,
                  itemBuilder: (context, index) {
                    final company = _availableCompanies[index];
                    final isSelected = company['id'] == _selectedCompanyId;
                    return ListTile(
                      leading: Icon(
                        Icons.business,
                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400],
                      ),
                      title: Text(company['name']),
                      subtitle: company['legal_name'] != null 
                        ? Text(company['legal_name'], style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                        : null,
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2563EB))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCompanyId = company['id'];
                          _companyController.text = company['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBankSelector(BuildContext context, String currentValue, Function(String) onChanged) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Seleccionar banco',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _banks.length,
                  itemBuilder: (context, index) {
                    final bank = _banks[index];
                    final isSelected = bank == currentValue ||
                        (currentValue == 'No especificado' && index == 0);
                    return ListTile(
                      leading: Icon(
                        Icons.account_balance,
                        color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400],
                      ),
                      title: Text(bank),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2563EB))
                          : null,
                      onTap: () {
                        onChanged(bank);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    // Verificar si se seleccionó una empresa
    if (_selectedCompanyId != null) {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      try {
        // Llamar al endpoint para unirse a la empresa
        await apiService.post('/api/employee-profiles/join-company/', data: {
          'company_id': _selectedCompanyId,
        });
        
        if (!mounted) return;
        
        // Cerrar loading
        Navigator.pop(context);
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Te has unido a la empresa exitosamente'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        
        // Refrescar el perfil para actualizar la empresa
        await context.read<AuthProvider>().refreshProfile();
        
        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        if (!mounted) return;
        
        // Cerrar loading
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al unirse a la empresa: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } else {
      // Si no hay empresa seleccionada, solo salir del modo edición
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _updatePassword(BuildContext context) async {
    final oldPassword = _currentPassController.text.trim();
    final newPassword = _newPassController.text.trim();
    final confirmPassword = _confirmPassController.text.trim();
    
    // Validaciones
    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu contraseña actual'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa la nueva contraseña'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe tener al menos 6 caracteres'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    
    if (oldPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nueva contraseña debe ser diferente a la actual'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    // Guardar referencias antes del await
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final authService = context.read<AuthService>();
      await authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      
      if (!mounted) return;
      
      // Cerrar loading
      navigator.pop();
      
      // Limpiar campos
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada exitosamente'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Cerrar loading
      navigator.pop();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintText: '••••••',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, {Color color = const Color(0xFF1E40AF)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
