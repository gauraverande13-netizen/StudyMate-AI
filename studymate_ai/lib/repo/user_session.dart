import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyToken = 'access_token';

  static Future<void> saveUserSession({
    required int userId,
    required String userName,
    required String email,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyUserId, userId);
    await prefs.setString(keyUserName, userName);
    await prefs.setString(keyUserEmail, email);
    if (token != null && token.isNotEmpty) {
      await prefs.setString(keyToken, token);
    }
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyUserId);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserEmail);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyUserId) != null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
    await prefs.remove(keyUserEmail);
    await prefs.remove(keyToken);
  }
}
