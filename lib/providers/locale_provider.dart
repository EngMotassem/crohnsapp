import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _hasSelectedLanguageKey = 'has_selected_language';
  
  Locale _locale = const Locale('ar');
  bool _hasSelectedLanguage = false;
  bool _isLoading = true;
  
  Locale get locale => _locale;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get isLoading => _isLoading;
  
  LocaleProvider() {
    _loadLocale();
  }
  
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey) ?? 'ar';
    _hasSelectedLanguage = prefs.getBool(_hasSelectedLanguageKey) ?? false;
    _locale = Locale(localeCode);
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> setLocale(Locale locale, {bool markAsSelected = false}) async {
    _locale = locale;
    
    if (markAsSelected) {
      _hasSelectedLanguage = true;
    }
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    if (markAsSelected) {
      await prefs.setBool(_hasSelectedLanguageKey, true);
    }
  }
  
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
  
  void toggleLocale() {
    if (isArabic) {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('ar'));
    }
  }
}
