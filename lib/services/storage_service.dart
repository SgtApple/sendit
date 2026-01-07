import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String keyMicroBlogToken = 'microblog_token';
  static const String keyXApiKey = 'x_api_key';
  static const String keyXApiSecret = 'x_api_secret';
  static const String keyXUserToken = 'x_user_token';
  static const String keyXUserSecret = 'x_user_secret';
  static const String keyTheme = 'app_theme';

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
