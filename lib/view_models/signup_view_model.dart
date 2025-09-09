import 'package:flutter/foundation.dart';
import '../auth/auth_service.dart';

class SignUpViewModel extends ChangeNotifier {
  String name = '';
  String email = '';
  String password = '';

  bool _loading = false;
  String? _error;
  String? _errorCode;

  bool get loading => _loading;
  String? get error => _error;
  String? get errorCode => _errorCode;

  void setName(String v) => name = v.trim();
  void setEmail(String v) => email = v.trim();
  void setPassword(String v) => password = v;

  Future<bool> signUpWithEmail() async {
    if (email.isEmpty || password.isEmpty) {
      _error = 'missing-credentials';
      _errorCode = 'missing-credentials';
      notifyListeners();
      return false;
    }
    _error = null;
    _errorCode = null;
    _loading = true;
    notifyListeners();

    try {
      final cred = await AuthService.instance
          .signUpWithEmail(email: email, password: password, displayName: name);
      final ok = cred.user != null;
      if (!ok) {
        _error = 'Authentication failed';
        _errorCode = null;
      }
      return ok;
    } on AuthException catch (e) {
      _error = e.message;
      _errorCode = e.code;
      return false;
    } catch (e) {
      _error = e.toString();
      _errorCode = null;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
