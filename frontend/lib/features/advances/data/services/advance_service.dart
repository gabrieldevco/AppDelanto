import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/advance_model.dart';

class AdvanceService {
  final ApiService _apiService;

  AdvanceService(this._apiService);

  // Crear nueva solicitud de adelanto
  Future<AdvanceModel> createAdvance({
    required double amount,
    required String reason,
  }) async {
    final response = await _apiService.post(
      ApiConstants.advances,
      data: {
        'amount': amount,
        'reason': reason,
      },
    );
    return AdvanceModel.fromJson(response);
  }

  // Obtener lista de adelantos del usuario actual
  Future<List<AdvanceModel>> getMyAdvances({int? page}) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;

    final response = await _apiService.get(
      ApiConstants.advances,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Manejar tanto lista simple como paginación
    final results = response is List ? response : (response['results'] ?? []);
    return results.map<AdvanceModel>((json) => AdvanceModel.fromJson(json)).toList();
  }

  // Obtener adelantos pendientes (para empleadores/admins)
  Future<List<AdvanceModel>> getPendingAdvances({int? page}) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;

    final response = await _apiService.get(
      ApiConstants.advancesPending,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final results = response is List ? response : (response['results'] ?? []);
    return results.map<AdvanceModel>((json) => AdvanceModel.fromJson(json)).toList();
  }

  // Obtener detalle de un adelanto
  Future<AdvanceModel> getAdvance(int id) async {
    final response = await _apiService.get('${ApiConstants.advances}$id/');
    return AdvanceModel.fromJson(response);
  }

  // Aprobar adelanto (empleador/admin)
  Future<AdvanceModel> approveAdvance(int id) async {
    final response = await _apiService.post(
      '${ApiConstants.advances}$id/approve/',
    );
    return AdvanceModel.fromJson(response);
  }

  // Rechazar adelanto (empleador/admin)
  Future<AdvanceModel> rejectAdvance(int id, {String? reason}) async {
    final data = <String, dynamic>{};
    if (reason != null) data['reason'] = reason;

    final response = await _apiService.post(
      '${ApiConstants.advances}$id/reject/',
      data: data.isNotEmpty ? data : null,
    );
    return AdvanceModel.fromJson(response);
  }

  // Marcar como desembolsado (empleador/admin)
  Future<AdvanceModel> disburseAdvance(
    int id, {
    required String reference,
  }) async {
    final response = await _apiService.post(
      '${ApiConstants.advances}$id/disburse/',
      data: {
        'disbursement_reference': reference,
      },
    );
    return AdvanceModel.fromJson(response);
  }

  // Cancelar solicitud propia (empleado)
  Future<AdvanceModel> cancelAdvance(int id) async {
    final response = await _apiService.post(
      '${ApiConstants.advances}$id/cancel/',
    );
    return AdvanceModel.fromJson(response);
  }

  // Obtener resumen/estadísticas de adelantos
  Future<Map<String, dynamic>> getAdvanceSummary() async {
    final response = await _apiService.get('${ApiConstants.advances}summary/');
    return response;
  }
}
