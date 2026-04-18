import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';

class AdminService {
  final ApiService _apiService;

  AdminService(this._apiService);

  // Obtener lista de usuarios
  Future<List<dynamic>> getUsers({String? role, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiConstants.adminUserManagement,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // Verificar empresa
  Future<Map<String, dynamic>> verifyCompany(int companyId) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.adminVerifyCompany}/$companyId/',
        data: {},
      );
      return response;
    } catch (e) {
      throw Exception('Error al verificar empresa: $e');
    }
  }

  // Obtener estadísticas del dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.get(ApiConstants.adminDashboard);
      return response;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
