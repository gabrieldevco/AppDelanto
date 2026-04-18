import 'package:flutter/foundation.dart';
import '../../data/models/company_model.dart';
import '../../data/services/company_service.dart';
import '../../../../core/services/api_service.dart';

enum CompanyStatus { initial, loading, loaded, submitting, success, error }

class CompanyProvider extends ChangeNotifier {
  final CompanyService _companyService;
  
  CompanyStatus _status = CompanyStatus.initial;
  CompanyModel? _myCompany;
  List<EmployeeModel> _employees = [];
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  CompanyProvider() : _companyService = CompanyService(apiService);

  // Getters
  CompanyStatus get status => _status;
  CompanyModel? get myCompany => _myCompany;
  List<EmployeeModel> get employees => _employees;
  List<EmployeeModel> get activeEmployees => 
    _employees.where((e) => e.isActive).toList();
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summary => _summary;
  bool get isLoading => _status == CompanyStatus.loading;
  bool get isSubmitting => _status == CompanyStatus.submitting;
  bool get hasCompany => _myCompany != null;

  // Cargar mi empresa (para empleadores)
  Future<void> loadMyCompany() async {
    _status = CompanyStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _myCompany = await _companyService.getMyCompany();
      _status = CompanyStatus.loaded;
    } catch (e) {
      _status = CompanyStatus.error;
      _errorMessage = 'Error al cargar empresa: ${e.toString()}';
    }
    notifyListeners();
  }

  // Crear empresa
  Future<bool> createCompany({
    required String name,
    String? legalName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    double? maxAdvancePercentage,
    double? advanceFeePercentage,
  }) async {
    _status = CompanyStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      _myCompany = await _companyService.createCompany(
        name: name,
        legalName: legalName,
        taxId: taxId,
        address: address,
        phone: phone,
        email: email,
        maxAdvancePercentage: maxAdvancePercentage,
        advanceFeePercentage: advanceFeePercentage,
      );
      
      _status = CompanyStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CompanyStatus.error;
      _errorMessage = 'Error al crear empresa: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Actualizar empresa
  Future<bool> updateCompany({
    String? name,
    String? legalName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    double? maxAdvancePercentage,
    double? advanceFeePercentage,
  }) async {
    if (_myCompany == null) return false;

    _status = CompanyStatus.submitting;
    notifyListeners();

    try {
      _myCompany = await _companyService.updateCompany(
        _myCompany!.id,
        name: name,
        legalName: legalName,
        taxId: taxId,
        address: address,
        phone: phone,
        email: email,
        maxAdvancePercentage: maxAdvancePercentage,
        advanceFeePercentage: advanceFeePercentage,
      );
      
      _status = CompanyStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CompanyStatus.error;
      _errorMessage = 'Error al actualizar empresa: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Cargar empleados de la empresa
  Future<void> loadEmployees({bool? active}) async {
    if (_myCompany == null) return;

    _status = CompanyStatus.loading;
    notifyListeners();

    try {
      _employees = await _companyService.getCompanyEmployees(
        _myCompany!.id,
        active: active,
      );
      _status = CompanyStatus.loaded;
    } catch (e) {
      _status = CompanyStatus.error;
      _errorMessage = 'Error al cargar empleados: ${e.toString()}';
    }
    notifyListeners();
  }

  // Agregar empleado
  Future<bool> addEmployee({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required double salary,
    String? phone,
    String? documentNumber,
    DateTime? hireDate,
  }) async {
    if (_myCompany == null) return false;

    _status = CompanyStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final newEmployee = await _companyService.addEmployee(
        companyId: _myCompany!.id,
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        salary: salary,
        phone: phone,
        documentNumber: documentNumber,
        hireDate: hireDate,
      );
      
      _employees.add(newEmployee);
      _status = CompanyStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CompanyStatus.error;
      _errorMessage = 'Error al agregar empleado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Actualizar empleado
  Future<bool> updateEmployee(
    int employeeId, {
    double? salary,
    double? availableAdvanceLimit,
    String? bankAccount,
    String? bankName,
    bool? isActive,
  }) async {
    if (_myCompany == null) return false;

    try {
      final updated = await _companyService.updateEmployee(
        _myCompany!.id,
        employeeId,
        salary: salary,
        availableAdvanceLimit: availableAdvanceLimit,
        bankAccount: bankAccount,
        bankName: bankName,
        isActive: isActive,
      );
      
      final index = _employees.indexWhere((e) => e.id == employeeId);
      if (index != -1) {
        _employees[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar empleado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Eliminar/Desactivar empleado
  Future<bool> removeEmployee(int employeeId) async {
    if (_myCompany == null) return false;

    try {
      await _companyService.removeEmployee(_myCompany!.id, employeeId);
      _employees.removeWhere((e) => e.id == employeeId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar empleado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Cargar configuración de empresa
  Future<void> loadSettings() async {
    if (_myCompany == null) return;

    try {
      final settings = await _companyService.getCompanySettings(_myCompany!.id);
      _myCompany = _myCompany!.copyWith(settings: settings);
      notifyListeners();
    } catch (e) {
      // Error silencioso
    }
  }

  // Actualizar configuración
  Future<bool> updateSettings({
    int? paymentDay,
    bool? notifyOnAdvanceRequest,
    bool? notifyOnAdvanceApproved,
    double? minAdvanceAmount,
    double? maxAdvanceAmount,
  }) async {
    if (_myCompany == null) return false;

    try {
      final settings = await _companyService.updateCompanySettings(
        _myCompany!.id,
        paymentDay: paymentDay,
        notifyOnAdvanceRequest: notifyOnAdvanceRequest,
        notifyOnAdvanceApproved: notifyOnAdvanceApproved,
        minAdvanceAmount: minAdvanceAmount,
        maxAdvanceAmount: maxAdvanceAmount,
      );
      
      _myCompany = _myCompany!.copyWith(settings: settings);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar configuración: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Cargar resumen de empresa
  Future<void> loadSummary() async {
    if (_myCompany == null) return;

    try {
      _summary = await _companyService.getCompanySummary(_myCompany!.id);
      notifyListeners();
    } catch (e) {
      // Error silencioso
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    if (_status == CompanyStatus.error) {
      _status = CompanyStatus.initial;
    }
    notifyListeners();
  }

  // Limpiar datos
  void clear() {
    _myCompany = null;
    _employees = [];
    _summary = null;
    _status = CompanyStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
