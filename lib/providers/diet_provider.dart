import 'package:flutter/foundation.dart';
import '../models/diet_model.dart';
import '../services/diet_service.dart';

class DietProvider extends ChangeNotifier {
  final DietService _dietService = DietService();
  
  List<DietEntry> _entries = [];
  List<FoodTrigger> _triggers = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  List<DietEntry> get entries => _entries;
  List<FoodTrigger> get triggers => _triggers;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToEntries(String userId) {
    _dietService.getDietEntriesStream(userId).listen((entries) {
      _entries = entries;
      notifyListeners();
    });
  }

  void listenToTriggers(String userId) {
    _dietService.getFoodTriggersStream(userId).listen((triggers) {
      _triggers = triggers;
      notifyListeners();
    });
  }

  Future<void> loadStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _statistics = await _dietService.getDietStatistics(
        userId,
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

  Future<List<DietEntry>> getEntriesByDate(String userId, DateTime date) async {
    try {
      return await _dietService.getDietEntriesByDate(userId, date);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> addEntry(DietEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dietService.addDietEntry(entry);
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

  Future<bool> updateEntry(DietEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dietService.updateDietEntry(entry);
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
      await _dietService.deleteDietEntry(entryId);
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

  Future<bool> removeTrigger(String triggerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _dietService.removeFoodTrigger(triggerId);
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

  bool isFoodKnownTrigger(String foodName) {
    return _triggers.any(
      (t) => t.foodName.toLowerCase() == foodName.toLowerCase(),
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
