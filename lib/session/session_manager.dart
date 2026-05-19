import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String KEY_LOGGED_IN = "logged_in";

  static Future<void> saveLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_LOGGED_IN, true);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_LOGGED_IN) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}