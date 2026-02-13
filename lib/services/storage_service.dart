import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // X (Twitter) credentials
  static const String keyXApiKey = 'x_api_key';
  static const String keyXApiSecret = 'x_api_secret';
  static const String keyXUserToken = 'x_user_token';
  static const String keyXUserSecret = 'x_user_secret';
  
  // Mastodon credentials
  static const String keyMastodonInstance = 'mastodon_instance';
  static const String keyMastodonToken = 'mastodon_token';
  
  // Bluesky credentials
  static const String keyBlueskyIdentifier = 'bluesky_identifier';
  static const String keyBlueskyPassword = 'bluesky_password';
  
  // Nostr credentials
  static const String keyNostrNsec = 'nostr_nsec';
  static const String keyNostrUseAmber = 'nostr_use_amber';
  static const String keyNostrNpub = 'nostr_npub';
  
  static const String keyTheme = 'app_theme';

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
  
  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }
}
