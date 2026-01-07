import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final StorageService _storage = StorageService();

  final _microBlogTokenController = TextEditingController();
  final _xApiKeyController = TextEditingController();
  final _xApiSecretController = TextEditingController();
  final _xUserTokenController = TextEditingController();
  final _xUserSecretController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _microBlogTokenController.text = await _storage.getString(StorageService.keyMicroBlogToken) ?? '';
    _xApiKeyController.text = await _storage.getString(StorageService.keyXApiKey) ?? '';
    _xApiSecretController.text = await _storage.getString(StorageService.keyXApiSecret) ?? '';
    _xUserTokenController.text = await _storage.getString(StorageService.keyXUserToken) ?? '';
    _xUserSecretController.text = await _storage.getString(StorageService.keyXUserSecret) ?? '';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _storage.saveString(StorageService.keyMicroBlogToken, _microBlogTokenController.text);
    await _storage.saveString(StorageService.keyXApiKey, _xApiKeyController.text);
    await _storage.saveString(StorageService.keyXApiSecret, _xApiSecretController.text);
    await _storage.saveString(StorageService.keyXUserToken, _xUserTokenController.text);
    await _storage.saveString(StorageService.keyXUserSecret, _xUserSecretController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildThemeSelector(),
          const Divider(height: 40),
          const Text('Micro.blog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _microBlogTokenController,
            decoration: const InputDecoration(labelText: 'App Token'),
            obscureText: true,
          ),
          const Divider(height: 40),
          const Text('X (Twitter)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _xApiKeyController,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _xApiSecretController,
            decoration: const InputDecoration(labelText: 'API Secret'),
            obscureText: true,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _xUserTokenController,
            decoration: const InputDecoration(labelText: 'Access Token'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _xUserSecretController,
            decoration: const InputDecoration(labelText: 'Access Token Secret'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themeService = context.watch<ThemeService>();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ThemeCard(
          label: 'Nord',
          isSelected: themeService.currentTheme == AppThemeType.nord,
          colors: [AppTheme.polarNight1, AppTheme.frost1],
          onTap: () => themeService.setTheme(AppThemeType.nord),
        ),
        _ThemeCard(
          label: 'Parchment',
          isSelected: themeService.currentTheme == AppThemeType.parchment,
          colors: [AppTheme.parchmentBg, AppTheme.parchmentAccent],
          onTap: () => themeService.setTheme(AppThemeType.parchment),
        ),
        _ThemeCard(
          label: 'Newspaper',
          isSelected: themeService.currentTheme == AppThemeType.newspaper,
          colors: [AppTheme.newspaperBg, AppTheme.newspaperText],
          onTap: () => themeService.setTheme(AppThemeType.newspaper),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _microBlogTokenController.dispose();
    _xApiKeyController.dispose();
    _xApiSecretController.dispose();
    _xUserTokenController.dispose();
    _xUserSecretController.dispose();
    super.dispose();
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: colors.map((c) => Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
