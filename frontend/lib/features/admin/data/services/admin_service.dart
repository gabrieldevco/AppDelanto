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

      if (response is List) {
        return response;
      }
      if (response is Map<String, dynamic>) {
        final results =
            response['results'] ?? response['data'] ?? response['users'];
        if (results is List) {
          return results;
        }
      }

      return <dynamic>[];
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

  Future<Map<String, dynamic>> getReports({
    required String startDate,
    required String endDate,
    int? employerId,
  }) async {
    final params = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (employerId != null) params['employer_id'] = employerId;

    final response = await _apiService.get(
      ApiConstants.adminReports,
      queryParameters: params,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _apiService.get(ApiConstants.adminSettings);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final response = await _apiService.patch(
      ApiConstants.adminSettings,
      data: data,
    );
    return response as Map<String, dynamic>;
  }
}
