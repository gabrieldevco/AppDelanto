import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../../data/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService;

  bool _isLoading = false;
  String? _error;
  List<dynamic> _users = [];
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _reports;
  Map<String, dynamic>? _settings;

  AdminProvider() : _adminService = AdminService(apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get users => _users;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  Map<String, dynamic>? get reports => _reports;
  Map<String, dynamic>? get settings => _settings;

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

  Future<void> loadReports({
    required String startDate,
    required String endDate,
    int? employerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reports = await _adminService.getReports(
        startDate: startDate,
        endDate: endDate,
        employerId: employerId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar reportes: $e';
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _adminService.getSettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar configuracion: $e';
      notifyListeners();
    }
  }

  Future<bool> updateSettings(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _adminService.updateSettings(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error al guardar configuracion: $e';
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
