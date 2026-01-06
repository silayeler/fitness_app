import 'package:flutter/foundation.dart';

/// AuthViewModel
/// MVVM yapısında login / kayıt ekranlarının iş mantığı ve state'ini
/// yönetmek için kullanılacak basit bir iskelet.
class AuthViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;

  void updateEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Şimdilik sadece iskelet: gerçek login/register akışını
  /// daha sonra Hive/local storage ile dolduracağız.
  Future<void> fakeLogin() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _setLoading(false);
  }

  Future<void> fakeRegister() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}


