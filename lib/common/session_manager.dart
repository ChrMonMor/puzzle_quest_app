import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Session login: lasts only while app is running
  static bool _sessionLoggedIn = false;

  // Persistent login (Remember Me)
  static bool _persistentLoggedIn = false;

  static bool get isLoggedIn => _persistentLoggedIn || _sessionLoggedIn;

  static Future<void> loadPersistentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    _persistentLoggedIn = prefs.getBool('loggedIn') ?? false;
  }

  static Future<void> login({required bool rememberMe}) async {
    _sessionLoggedIn = true;
    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      _persistentLoggedIn = true;
    }
  }

  static Future<void> logout() async {
    _sessionLoggedIn = false;
    _persistentLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
  }
}
