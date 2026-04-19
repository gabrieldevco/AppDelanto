import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConstants.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );

    // Guardar token
    if (response['token'] != null) {
      await _apiService.setAuthToken(response['token']);
    }

    return response;
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
    String? documentNumber,
    double? salary,
    String? businessName,
    String? companyName,
    int? companyId,
    File? chamberOfCommerceFile,
    String? bankAccount,
    String? bankName,
  }) async {
    try {
      // Crear FormData para soporte de archivos - de forma segura
      final Map<String, dynamic> formMap = {
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      };
      
      // Agregar campos opcionales solo si no son null ni vacíos
      if (phone != null && phone.isNotEmpty) {
        formMap['phone'] = phone;
      }
      if (documentNumber != null && documentNumber.isNotEmpty) {
        formMap['document_number'] = documentNumber;
      }
      if (salary != null) {
        formMap['salary'] = salary.toString();
      }
      if (businessName != null && businessName.isNotEmpty) {
        formMap['business_name'] = businessName;
      }
      if (companyName != null && companyName.isNotEmpty) {
        formMap['company_name'] = companyName;
      }
      if (bankAccount != null && bankAccount.isNotEmpty) {
        formMap['bank_account'] = bankAccount;
      }
      if (bankName != null && bankName.isNotEmpty) {
        formMap['bank_name'] = bankName;
      }
      if (companyId != null) {
        formMap['company_id'] = companyId.toString();
      }
      
      // Archivo PDF de cámara de comercio
      if (chamberOfCommerceFile != null) {
        formMap['chamber_of_commerce_document'] = await MultipartFile.fromFile(
          chamberOfCommerceFile.path,
          filename: chamberOfCommerceFile.path.split('/').last,
        );
      }
      
      final formData = FormData.fromMap(formMap);

      final response = await _apiService.dio.post(
        ApiConstants.authRegister,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;

      // Guardar token si viene en el registro
      if (data['token'] != null) {
        await _apiService.setAuthToken(data['token']);
      }

      return data;
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Obtener token antes de limpiarlo
      final token = await _getToken();
      if (token != null) {
        await _apiService.post(
          ApiConstants.authLogout,
          options: Options(headers: {'Authorization': 'Token $token'}),
        );
      }
    } catch (e) {
      // Ignorar errores de logout
    } finally {
      await _apiService.clearAuthToken();
    }
  }

  // Obtener token guardado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get current user profile
  Future<UserModel> getProfile() async {
    final response = await _apiService.get(ApiConstants.authProfile);
    return UserModel.fromJson(response);
  }

  // Update profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? documentNumber,
    String? bankAccount,
    String? bankName,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (documentNumber != null) data['document_number'] = documentNumber;
    if (bankAccount != null) data['bank_account'] = bankAccount;
    if (bankName != null) data['bank_name'] = bankName;

    final response = await _apiService.put(
      ApiConstants.authProfile,
      data: data,
    );

    return UserModel.fromJson(response);
  }

  // Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiService.post(
      ApiConstants.authPasswordChange,
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  // Check if authenticated
  bool get isAuthenticated => _apiService.isAuthenticated;

  // Initialize auth (load token)
  Future<void> initialize() async {
    await _apiService.initialize();
  }
}
