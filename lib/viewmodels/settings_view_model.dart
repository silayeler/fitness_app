import 'package:flutter/foundation.dart';

/// SettingsViewModel
/// Dil, tema, veri temizleme gibi ayarlar için MVVM iskeleti.
class SettingsViewModel extends ChangeNotifier {
  bool _isDarkMode = false;
  String _languageCode = 'tr';

  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }
}


