import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/company_model.dart';

class CompanyService {
  final ApiService _apiService;

  CompanyService(this._apiService);

  // Obtener mi empresa (para empleadores)
  Future<CompanyModel?> getMyCompany() async {
    try {
      final response = await _apiService.get(ApiConstants.myCompany);
      return CompanyModel.fromJson(response);

      // Si es una lista, tomar el primero (debería ser solo una empresa por empleador)

      // Si es paginado
    } catch (e) {
      return null;
    }
  }

  // Obtener detalle de empresa específica
  Future<CompanyModel> getCompany(int id) async {
    final response = await _apiService.get('${ApiConstants.companies}$id/');
    return CompanyModel.fromJson(response);
  }

  Future<CompanyModel> uploadPlatformContract({
    required int companyId,
    required File file,
  }) async {
    final formData = FormData.fromMap({
      'platform_contract_file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _apiService.dio.post(
      '${ApiConstants.companies}$companyId/upload_platform_contract/',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw ApiException(
        message: response.data.toString(),
        statusCode: response.statusCode,
        data: response.data,
      );
    }
    return CompanyModel.fromJson(response.data);
  }

  Future<CompanyModel> uploadSubscriptionReceipt({
    required int companyId,
    required File file,
  }) async {
    final formData = FormData.fromMap({
      'subscription_receipt_file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    final response = await _apiService.dio.post(
      '${ApiConstants.companies}$companyId/upload_subscription_receipt/',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw ApiException(
        message: response.data.toString(),
        statusCode: response.statusCode,
        data: response.data,
      );
    }
    return CompanyModel.fromJson(response.data);
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
    String? bankAccount,
    String? bankName,
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
      'bank_account': bankAccount,
      'bank_name': bankName,
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
    String? bankAccount,
    String? bankName,
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
    if (bankAccount != null) data['bank_account'] = bankAccount;
    if (bankName != null) data['bank_name'] = bankName;

    final response = await _apiService.patch(
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
      ApiConstants.employeeProfiles,
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
    String? bankAccount,
    String? bankName,
    DateTime? hireDate,
    File? contractFile,
    String? contractTitle,
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
      'bank_account': bankAccount,
      'bank_name': bankName,
      'hire_date': hireDate?.toIso8601String(),
      'contract_title': contractTitle,
    };

    if (contractFile != null) {
      final formData = FormData.fromMap(
        data..removeWhere((key, value) => value == null),
      );
      formData.files.add(
        MapEntry(
          'contract_file',
          await MultipartFile.fromFile(
            contractFile.path,
            filename: contractFile.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
      final response = await _apiService.post(
        '${ApiConstants.companies}$companyId/employees/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return EmployeeModel.fromJson(response);
    }

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

    final response = await _apiService.patch(
      '${ApiConstants.employeeProfiles}$employeeId/',
      data: data,
    );
    return EmployeeModel.fromJson(response);
  }

  // Eliminar/Desactivar empleado
  Future<void> removeEmployee(int companyId, int employeeId) async {
    await _apiService.delete('${ApiConstants.employeeProfiles}$employeeId/');
  }

  // Obtener resumen/estadísticas de la empresa
  Future<Map<String, dynamic>> getCompanySummary(int companyId) async {
    final response = await _apiService.get(
      '${ApiConstants.companies}$companyId/summary/',
    );
    return response;
  }
}
