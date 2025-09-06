import 'package:flutter/material.dart';

class LanguageService with ChangeNotifier {
  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String newLanguage) {
    if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;
      notifyListeners();
    }
  }
}