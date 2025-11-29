import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';
import '../services/medication_service.dart';

class MedicationProvider extends ChangeNotifier {
  final MedicationService _medicationService = MedicationService();
  
  List<Medication> _activeMedications = [];
  List<MedicationLog> _todaysLogs = [];
  Map<String, dynamic>? _adherenceStats;
  bool _isLoading = false;
  String? _error;

  List<Medication> get activeMedications => _activeMedications;
  List<MedicationLog> get todaysLogs => _todaysLogs;
  Map<String, dynamic>? get adherenceStats => _adherenceStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToMedications(String oderId) {
    _medicationService.getActiveMedicationsStream(oderId).listen((medications) {
      _activeMedications = medications;
      notifyListeners();
    });
  }

  void listenToTodaysLogs(String oderId) {
    _medicationService.getMedicationLogsStream(oderId, DateTime.now()).listen((logs) {
      _todaysLogs = logs;
      notifyListeners();
    });
  }

  Future<void> loadAdherenceStats(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _adherenceStats = await _medicationService.getAdherenceStatistics(
        oderId,
        startDate,
        endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicationService.addMedication(medication);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicationService.updateMedication(medication);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateMedication(String medicationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicationService.deactivateMedication(medicationId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logMedicationTaken(MedicationLog log) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _medicationService.logMedicationTaken(log);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<String>> getCommonSideEffects(String oderId) async {
    try {
      return await _medicationService.getCommonSideEffects(oderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  bool isMedicationLoggedToday(String medicationId) {
    return _todaysLogs.any((log) => log.medicationId == medicationId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
