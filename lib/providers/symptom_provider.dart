import 'package:flutter/foundation.dart';
import '../models/symptom_model.dart';
import '../services/symptom_service.dart';

class SymptomProvider extends ChangeNotifier {
  final SymptomService _symptomService = SymptomService();
  
  List<SymptomEntry> _entries = [];
  SymptomEntry? _todaysEntry;
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  List<SymptomEntry> get entries => _entries;
  SymptomEntry? get todaysEntry => _todaysEntry;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToSymptoms(String oderId) {
    _symptomService.getSymptomEntriesStream(oderId).listen((entries) {
      _entries = entries;
      notifyListeners();
    });
  }

  Future<void> loadTodaysEntry(String oderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todaysEntry = await _symptomService.getTodaysEntry(oderId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics(
    String oderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _statistics = await _symptomService.getSymptomStatistics(
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

  Future<bool> addEntry(SymptomEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _symptomService.addSymptomEntry(entry);
      _todaysEntry = entry;
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

  Future<bool> updateEntry(SymptomEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _symptomService.updateSymptomEntry(entry);
      if (_todaysEntry?.id == entry.id) {
        _todaysEntry = entry;
      }
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

  Future<bool> deleteEntry(String entryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _symptomService.deleteSymptomEntry(entryId);
      if (_todaysEntry?.id == entryId) {
        _todaysEntry = null;
      }
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

  Future<List<SymptomEntry>> getFlareEntries(String oderId) async {
    try {
      return await _symptomService.getFlareEntries(oderId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
