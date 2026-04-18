import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/company_model.dart';

class CompanyService {
  final ApiService _apiService;

  CompanyService(this._apiService);

  // Obtener mi empresa (para empleadores)
  Future<CompanyModel?> getMyCompany() async {
    try {
      final response = await _apiService.get(ApiConstants.companies);
      
      // Si es una lista, tomar el primero (debería ser solo una empresa por empleador)
      if (response is List && response.isNotEmpty) {
        return CompanyModel.fromJson(response[0]);
      }
      
      // Si es paginado
      if (response['results'] != null && response['results'].isNotEmpty) {
        return CompanyModel.fromJson(response['results'][0]);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Obtener detalle de empresa específica
  Future<CompanyModel> getCompany(int id) async {
    final response = await _apiService.get('${ApiConstants.companies}$id/');
    return CompanyModel.fromJson(response);
  }

  // Crear empresa (registro de empleador)
  Future<CompanyModel> createCompany({
    required String name,
    String? legalName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    double? maxAdvancePercentage,
    double? advanceFeePercentage,
  }) async {
    final data = {
      'name': name,
      'legal_name': legalName,
      'tax_id': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'max_advance_percentage': maxAdvancePercentage ?? 50.0,
      'advance_fee_percentage': advanceFeePercentage ?? 2.0,
    };

    final response = await _apiService.post(
      ApiConstants.companies,
      data: data..removeWhere((key, value) => value == null),
    );
    return CompanyModel.fromJson(response);
  }

  // Actualizar empresa
  Future<CompanyModel> updateCompany(
    int id, {
    String? name,
    String? legalName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    double? maxAdvancePercentage,
    double? advanceFeePercentage,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (legalName != null) data['legal_name'] = legalName;
    if (taxId != null) data['tax_id'] = taxId;
    if (address != null) data['address'] = address;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (maxAdvancePercentage != null) {
      data['max_advance_percentage'] = maxAdvancePercentage;
    }
    if (advanceFeePercentage != null) {
      data['advance_fee_percentage'] = advanceFeePercentage;
    }
    if (isActive != null) data['is_active'] = isActive;

    final response = await _apiService.put(
      '${ApiConstants.companies}$id/',
      data: data,
    );
    return CompanyModel.fromJson(response);
  }

  // Obtener configuración de empresa
  Future<CompanySettings> getCompanySettings(int companyId) async {
    final response = await _apiService.get(
      '${ApiConstants.companies}$companyId/settings/',
    );
    return CompanySettings.fromJson(response);
  }

  // Actualizar configuración de empresa
  Future<CompanySettings> updateCompanySettings(
    int companyId, {
    int? paymentDay,
    bool? notifyOnAdvanceRequest,
    bool? notifyOnAdvanceApproved,
    double? minAdvanceAmount,
    double? maxAdvanceAmount,
  }) async {
    final data = <String, dynamic>{};
    if (paymentDay != null) data['payment_day'] = paymentDay;
    if (notifyOnAdvanceRequest != null) {
      data['notify_on_advance_request'] = notifyOnAdvanceRequest;
    }
    if (notifyOnAdvanceApproved != null) {
      data['notify_on_advance_approved'] = notifyOnAdvanceApproved;
    }
    if (minAdvanceAmount != null) data['min_advance_amount'] = minAdvanceAmount;
    if (maxAdvanceAmount != null) data['max_advance_amount'] = maxAdvanceAmount;

    final response = await _apiService.put(
      '${ApiConstants.companies}$companyId/settings/',
      data: data,
    );
    return CompanySettings.fromJson(response);
  }

  // Obtener empleados de la empresa
  Future<List<EmployeeModel>> getCompanyEmployees(
    int companyId, {
    int? page,
    bool? active,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (active != null) queryParams['is_active'] = active;

    final response = await _apiService.get(
      '${ApiConstants.companies}$companyId/employees/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final results = response is List ? response : (response['results'] ?? []);
    return results
        .map<EmployeeModel>((json) => EmployeeModel.fromJson(json))
        .toList();
  }

  // Agregar empleado a la empresa
  Future<EmployeeModel> addEmployee({
    required int companyId,
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
    final data = {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'salary': salary,
      'phone': phone,
      'document_number': documentNumber,
      'hire_date': hireDate?.toIso8601String(),
    };

    final response = await _apiService.post(
      '${ApiConstants.companies}$companyId/employees/',
      data: data..removeWhere((key, value) => value == null),
    );
    return EmployeeModel.fromJson(response);
  }

  // Actualizar empleado
  Future<EmployeeModel> updateEmployee(
    int companyId,
    int employeeId, {
    double? salary,
    double? availableAdvanceLimit,
    String? bankAccount,
    String? bankName,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (salary != null) data['salary'] = salary;
    if (availableAdvanceLimit != null) {
      data['available_advance_limit'] = availableAdvanceLimit;
    }
    if (bankAccount != null) data['bank_account'] = bankAccount;
    if (bankName != null) data['bank_name'] = bankName;
    if (isActive != null) data['is_active'] = isActive;

    final response = await _apiService.put(
      '${ApiConstants.companies}$companyId/employees/$employeeId/',
      data: data,
    );
    return EmployeeModel.fromJson(response);
  }

  // Eliminar/Desactivar empleado
  Future<void> removeEmployee(int companyId, int employeeId) async {
    await _apiService.delete(
      '${ApiConstants.companies}$companyId/employees/$employeeId/',
    );
  }

  // Obtener resumen/estadísticas de la empresa
  Future<Map<String, dynamic>> getCompanySummary(int companyId) async {
    final response = await _apiService.get(
      '${ApiConstants.companies}$companyId/summary/',
    );
    return response;
  }
}
