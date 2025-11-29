import 'package:flutter/foundation.dart';
import '../models/mood_model.dart';
import '../services/mood_service.dart';

class MoodProvider extends ChangeNotifier {
  final MoodService _moodService = MoodService();
  
  List<MoodEntry> _entries = [];
  MoodEntry? _todaysEntry;
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  List<MoodEntry> get entries => _entries;
  MoodEntry? get todaysEntry => _todaysEntry;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToEntries(String userId) {
    _moodService.getMoodEntriesStream(userId).listen((entries) {
      _entries = entries;
      notifyListeners();
    });
  }

  Future<void> loadTodaysEntry(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todaysEntry = await _moodService.getTodaysEntry(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStatistics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      _statistics = await _moodService.getMoodStatistics(
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

  Future<bool> addEntry(MoodEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _moodService.addMoodEntry(entry);
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

  Future<bool> updateEntry(MoodEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _moodService.updateMoodEntry(entry);
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
      await _moodService.deleteMoodEntry(entryId);
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

  Future<List<String>> getCommonCopingStrategies(String userId) async {
    try {
      return await _moodService.getCommonCopingStrategies(userId);
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
