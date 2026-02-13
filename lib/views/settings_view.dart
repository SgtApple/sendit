import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/nostr_service.dart';
import '../services/theme_service.dart';
import '../theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final StorageService _storage = StorageService();

  // Mastodon
  final _mastodonInstanceController = TextEditingController();
  final _mastodonTokenController = TextEditingController();
  
  // Bluesky
  final _blueskyIdentifierController = TextEditingController();
  final _blueskyPasswordController = TextEditingController();
  
  // Nostr
  final _nostrNsecController = TextEditingController();
  final _nostrNpubController = TextEditingController();
  bool _nostrUseAmber = false;
  
  // X (Twitter)
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
    // Mastodon
    _mastodonInstanceController.text = await _storage.getString(StorageService.keyMastodonInstance) ?? '';
    _mastodonTokenController.text = await _storage.getString(StorageService.keyMastodonToken) ?? '';
    
    // Bluesky
    _blueskyIdentifierController.text = await _storage.getString(StorageService.keyBlueskyIdentifier) ?? '';
    _blueskyPasswordController.text = await _storage.getString(StorageService.keyBlueskyPassword) ?? '';
    
    // Nostr
    _nostrNsecController.text = await _storage.getString(StorageService.keyNostrNsec) ?? '';
    _nostrNpubController.text = await _storage.getString(StorageService.keyNostrNpub) ?? '';
    _nostrUseAmber = await _storage.getBool(StorageService.keyNostrUseAmber);
    
    // X
    _xApiKeyController.text = await _storage.getString(StorageService.keyXApiKey) ?? '';
    _xApiSecretController.text = await _storage.getString(StorageService.keyXApiSecret) ?? '';
    _xUserTokenController.text = await _storage.getString(StorageService.keyXUserToken) ?? '';
    _xUserSecretController.text = await _storage.getString(StorageService.keyXUserSecret) ?? '';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // Mastodon
    await _storage.saveString(StorageService.keyMastodonInstance, _mastodonInstanceController.text);
    await _storage.saveString(StorageService.keyMastodonToken, _mastodonTokenController.text);
    
    // Bluesky
    await _storage.saveString(StorageService.keyBlueskyIdentifier, _blueskyIdentifierController.text);
    await _storage.saveString(StorageService.keyBlueskyPassword, _blueskyPasswordController.text);
    
    // Nostr
    await _storage.saveString(StorageService.keyNostrNsec, _nostrNsecController.text);
    await _storage.saveString(StorageService.keyNostrNpub, _nostrNpubController.text);
    await _storage.saveBool(StorageService.keyNostrUseAmber, _nostrUseAmber);
    
    // X
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
          const Text('Mastodon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _mastodonInstanceController,
            decoration: const InputDecoration(
              labelText: 'Instance (e.g., mastodon.social)',
              hintText: 'mastodon.social',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mastodonTokenController,
            decoration: const InputDecoration(labelText: 'Access Token'),
            obscureText: true,
          ),
          
          const Divider(height: 40),
          const Text('Bluesky', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _blueskyIdentifierController,
            decoration: const InputDecoration(
              labelText: 'Handle or Email',
              hintText: 'username.bsky.social',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _blueskyPasswordController,
            decoration: const InputDecoration(labelText: 'App Password'),
            obscureText: true,
          ),
          
          const Divider(height: 40),
          const Text('Nostr', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (Platform.isAndroid)
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Amber for signing'),
                  subtitle: const Text('Connect to Amber signer app (NIP-55)'),
                  value: _nostrUseAmber,
                  onChanged: (value) async {
                    if (value) {
                      // Request public key from Amber using amberflutter
                      try {
                        final nostrService = context.read<NostrService>();
                        final npub = await nostrService.getPublicKeyFromAmber();
                        
                        if (npub != null && mounted) {
                          setState(() {
                            _nostrNpubController.text = npub;
                            _nostrUseAmber = true;
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connected to Amber successfully!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to connect to Amber'),
                            ),
                          );
                          return;
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error connecting to Amber: $e')),
                          );
                        }
                        return;
                      }
                    } else {
                      setState(() {
                        _nostrUseAmber = value;
                      });
                    }
                  },
                ),
                if (_nostrNpubController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Connected: ${_nostrNpubController.text.substring(0, 16)}...',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ),
              ],
            ),
          if (!_nostrUseAmber || !Platform.isAndroid)
            Column(
              children: [
                TextField(
                  controller: _nostrNpubController,
                  decoration: const InputDecoration(
                    labelText: 'Public Key (npub)',
                    hintText: 'npub1...',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nostrNsecController,
                  decoration: const InputDecoration(
                    labelText: 'Private Key (nsec)',
                    hintText: 'nsec1...',
                  ),
                  obscureText: true,
                ),
              ],
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
    _mastodonInstanceController.dispose();
    _mastodonTokenController.dispose();
    _blueskyIdentifierController.dispose();
    _blueskyPasswordController.dispose();
    _nostrNsecController.dispose();
    _nostrNpubController.dispose();
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
