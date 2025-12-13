import 'package:flutter/foundation.dart';

/// ProfileViewModel
/// Kullanıcı profil bilgileri ve özet istatistikler için MVVM iskeleti.
class ProfileViewModel extends ChangeNotifier {
  String _displayName = '';
  String _email = '';

  String get displayName => _displayName;
  String get email => _email;

  void updateProfile({String? displayName, String? email}) {
    if (displayName != null) _displayName = displayName;
    if (email != null) _email = email;
    notifyListeners();
  }
}


