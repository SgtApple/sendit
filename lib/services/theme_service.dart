import 'package:flutter/foundation.dart';
import '../theme.dart';
import 'storage_service.dart';

class ThemeService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  AppThemeType _currentTheme = AppThemeType.nord;

  AppThemeType get currentTheme => _currentTheme;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeName = await _storage.getString(StorageService.keyTheme);
    if (themeName != null) {
      _currentTheme = AppThemeType.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeType.nord,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    _currentTheme = theme;
    await _storage.saveString(StorageService.keyTheme, theme.name);
    notifyListeners();
  }
}
