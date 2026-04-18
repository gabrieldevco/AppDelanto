import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../data/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;
  
  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  Map<String, dynamic>? _dashboardStats;

  AdminProvider() : _adminService = AdminService(apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get users => _users;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;

  // Cargar lista de usuarios
  Future<void> loadUsers({String? role, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _adminService.getUsers(role: role, search: search);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar usuarios: $e';
      notifyListeners();
    }
  }

  // Verificar empresa
  Future<bool> verifyCompany(int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _adminService.verifyCompany(companyId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al verificar empresa: $e';
      notifyListeners();
      return false;
    }
  }

  // Cargar estadísticas del dashboard
  Future<void> loadDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardStats = await _adminService.getDashboardStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar estadísticas: $e';
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
