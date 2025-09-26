import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._prefs) {
    _isSignedIn = _prefs.getBool(_signedInKey) ?? false;
  }

  final SharedPreferences _prefs;
  static const String _signedInKey = 'signedIn';
  static const String _emailKey = 'email';

  late bool _isSignedIn;
  bool get isSignedIn => _isSignedIn;

  String? get email => _prefs.getString(_emailKey);

  Future<bool> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _isSignedIn = true;
    await _prefs.setBool(_signedInKey, true);
    await _prefs.setString(_emailKey, email);
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    await _prefs.setBool(_signedInKey, false);
    await _prefs.remove(_emailKey);
    notifyListeners();
  }
}


