import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionManager {
  static bool _sessionLoggedIn = false;
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
    await prefs.remove('token');
  }

  // ---------------- Token Refresh / Guest Init ----------------
  // Returns a valid token (existing or freshly initialized guest) or null if failed.
  static Future<String?> ensureGuestToken({String baseUrl = 'http://pro-xi-mi-ty-srv', http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    if (token != null && token.isNotEmpty) return token;

    final httpClient = client ?? http.Client();
    final url = Uri.parse('$baseUrl/api/guests/init');
    try {
      final resp = await httpClient.post(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        final guest = data['guest_uuid'];
        if (guest is String && guest.isNotEmpty) {
          await prefs.setString('token', guest);
          return guest;
        }
      }
    } catch (_) {}
    return null;
  }

  // Attempt to refresh when 401 token expired encountered. Strategy:
  // 1. Clear existing token
  // 2. Initialize new guest token
  // Returns new token or null if still failing.
  static Future<String?> refreshExpiredToken({String baseUrl = 'http://pro-xi-mi-ty-srv', http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    return ensureGuestToken(baseUrl: baseUrl, client: client);
  }
}
