import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _userNameKey = 'user_name';

  /// Save the user's name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// Get the user's name (returns null if not set)
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Check if user name has been set
  static Future<bool> hasUserName() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }

  /// Clear the user's name
  static Future<void> clearUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
  }
}
