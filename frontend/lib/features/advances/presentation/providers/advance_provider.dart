import 'package:flutter/foundation.dart';
import '../../data/models/advance_model.dart';
import '../../data/services/advance_service.dart';
import '../../../../core/services/api_service.dart';

enum AdvanceStatus { initial, loading, loaded, submitting, success, error }

class AdvanceProvider extends ChangeNotifier {
  final AdvanceService _advanceService;
  
  AdvanceStatus _status = AdvanceStatus.initial;
  List<AdvanceModel> _advances = [];
  List<AdvanceModel> _pendingAdvances = [];
  AdvanceModel? _selectedAdvance;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  AdvanceProvider() : _advanceService = AdvanceService(apiService);

  // Getters
  AdvanceStatus get status => _status;
  List<AdvanceModel> get advances => _advances;
  List<AdvanceModel> get pendingAdvances => _pendingAdvances;
  List<AdvanceModel> get myPendingAdvances => 
    _advances.where((a) => a.isPending).toList();
  List<AdvanceModel> get myApprovedAdvances => 
    _advances.where((a) => a.isApproved || a.isDisbursed).toList();
  List<AdvanceModel> get myHistory => 
    _advances.where((a) => a.isRecovered || a.isRejected || a.isCancelled).toList();
  
  AdvanceModel? get selectedAdvance => _selectedAdvance;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get summary => _summary;
  bool get isLoading => _status == AdvanceStatus.loading;
  bool get isSubmitting => _status == AdvanceStatus.submitting;

  // Cargar mis adelantos (empleado)
  Future<void> loadMyAdvances() async {
    _status = AdvanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _advances = await _advanceService.getMyAdvances();
      _status = AdvanceStatus.loaded;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al cargar adelantos: ${e.toString()}';
    }
    notifyListeners();
  }

  // Cargar adelantos pendientes (empleador/admin)
  Future<void> loadPendingAdvances() async {
    _status = AdvanceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingAdvances = await _advanceService.getPendingAdvances();
      _status = AdvanceStatus.loaded;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al cargar solicitudes pendientes: ${e.toString()}';
    }
    notifyListeners();
  }

  // Crear solicitud de adelanto
  Future<bool> createAdvance({
    required double amount,
    required String reason,
  }) async {
    _status = AdvanceStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      final newAdvance = await _advanceService.createAdvance(
        amount: amount,
        reason: reason,
      );
      
      _advances.insert(0, newAdvance);
      _status = AdvanceStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al solicitar adelanto: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Aprobar adelanto (empleador/admin)
  Future<bool> approveAdvance(int advanceId) async {
    _status = AdvanceStatus.submitting;
    notifyListeners();

    try {
      final updated = await _advanceService.approveAdvance(advanceId);
      
      // Actualizar en la lista de pendientes
      final index = _pendingAdvances.indexWhere((a) => a.id == advanceId);
      if (index != -1) {
        _pendingAdvances[index] = updated;
        _pendingAdvances.removeAt(index);
      }
      
      _status = AdvanceStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al aprobar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Rechazar adelanto (empleador/admin)
  Future<bool> rejectAdvance(int advanceId, {String? reason}) async {
    _status = AdvanceStatus.submitting;
    notifyListeners();

    try {
      await _advanceService.rejectAdvance(advanceId, reason: reason);
      
      final index = _pendingAdvances.indexWhere((a) => a.id == advanceId);
      if (index != -1) {
        _pendingAdvances.removeAt(index);
      }
      
      _status = AdvanceStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al rechazar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Marcar como desembolsado (empleador/admin)
  Future<bool> disburseAdvance(int advanceId, {required String reference}) async {
    _status = AdvanceStatus.submitting;
    notifyListeners();

    try {
      final updated = await _advanceService.disburseAdvance(
        advanceId,
        reference: reference,
      );
      
      _updateAdvanceInList(updated);
      _status = AdvanceStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al desembolsar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Cancelar solicitud propia (empleado)
  Future<bool> cancelAdvance(int advanceId) async {
    _status = AdvanceStatus.submitting;
    notifyListeners();

    try {
      final updated = await _advanceService.cancelAdvance(advanceId);
      
      _updateAdvanceInList(updated);
      _status = AdvanceStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AdvanceStatus.error;
      _errorMessage = 'Error al cancelar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Obtener detalle de adelanto
  Future<void> getAdvanceDetail(int advanceId) async {
    try {
      _selectedAdvance = await _advanceService.getAdvance(advanceId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar detalle: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cargar resumen de adelantos
  Future<void> loadSummary() async {
    try {
      _summary = await _advanceService.getAdvanceSummary();
      notifyListeners();
    } catch (e) {
      // No mostrar error silencioso
    }
  }

  // Helper para actualizar adelanto en lista
  void _updateAdvanceInList(AdvanceModel updated) {
    final index = _advances.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _advances[index] = updated;
    }
    
    final pendingIndex = _pendingAdvances.indexWhere((a) => a.id == updated.id);
    if (pendingIndex != -1) {
      _pendingAdvances[pendingIndex] = updated;
    }
    
    if (_selectedAdvance?.id == updated.id) {
      _selectedAdvance = updated;
    }
  }

  // Limpiar error
  void clearError() {
    _errorMessage = null;
    if (_status == AdvanceStatus.error) {
      _status = AdvanceStatus.initial;
    }
    notifyListeners();
  }

  // Limpiar selección
  void clearSelection() {
    _selectedAdvance = null;
    notifyListeners();
  }
}
