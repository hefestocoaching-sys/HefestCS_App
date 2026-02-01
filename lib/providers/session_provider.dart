import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  String? _clientId;
  String? _displayName;

  String? get clientId => _clientId;
  String? get displayName => _displayName;
  bool get isLoggedIn => _clientId != null && _displayName != null;

  void setSession({
    required String clientId,
    required String displayName,
  }) {
    _clientId = clientId;
    _displayName = displayName;
    debugPrint('✅ Sesión iniciada: $_clientId / $_displayName');
    notifyListeners();
  }

  void clearSession() {
    _clientId = null;
    _displayName = null;
    debugPrint('🚪 Sesión cerrada');
    notifyListeners();
  }
}
