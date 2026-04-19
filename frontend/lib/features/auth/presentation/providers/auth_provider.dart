import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../notifications/presentation/providers/notification_provider.dart' as main_notifications;
import '../../../employer/presentation/widgets/employer_notifications_drawer.dart';
import '../../../admin/presentation/widgets/admin_notifications_drawer.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _token;

  AuthProvider() : _authService = AuthService(apiService);

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isEmployee => _user?.isEmployee ?? false;
  bool get isEmployer => _user?.isEmployer ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Inicializar - verificar si hay sesión guardada
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.initialize();
      
      if (_authService.isAuthenticated) {
        _user = await _authService.getProfile();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _token = null;  // Limpiar token anterior
    _user = null;  // Limpiar usuario anterior
    // Limpiar notificaciones de todos los roles
    EmployerNotificationProvider.clearNotifications();
    AdminNotificationProvider.clearNotifications();
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      
      _token = response['token'];
      
      // Obtener perfil después de login
      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Usuario o contraseña incorrectos';
      notifyListeners();
      return false;
    }
  }

  // Registro con soporte para archivos y campos adicionales
  Future<bool> register({
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
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: phone,
        documentNumber: documentNumber,
        salary: salary,
        businessName: businessName,
        companyName: companyName,
        companyId: companyId,
        chamberOfCommerceFile: chamberOfCommerceFile,
        bankAccount: bankAccount,
        bankName: bankName,
      );
      
      _token = response['token'];
      _user = await _authService.getProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      
      // Mostrar mensaje exacto del backend
      String errorMsg = e.toString();
      // Limpiar el prefijo "ApiException: " si existe
      if (errorMsg.startsWith('ApiException: ')) {
        errorMsg = errorMsg.substring('ApiException: '.length);
      }
      // Extraer solo el mensaje antes de "(Status:"
      if (errorMsg.contains(' (Status:')) {
        errorMsg = errorMsg.split(' (Status:')[0];
      }
      
      _errorMessage = errorMsg;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignorar errores de logout
    }

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    // Limpiar notificaciones al cerrar sesión
    EmployerNotificationProvider.clearNotifications();
    AdminNotificationProvider.clearNotifications();
    notifyListeners();
  }

  // Actualizar perfil
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? documentNumber,
    String? bankAccount,
    String? bankName,
  }) async {
    try {
      final updatedUser = await _authService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        documentNumber: documentNumber,
        bankAccount: bankAccount,
        bankName: bankName,
      );
      
      _user = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar perfil: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Cambiar contraseña
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Error al cambiar contraseña: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Refrescar perfil
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (e) {
      // No actualizar status en error silencioso
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
