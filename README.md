# SendIt

A minimalist cross-platform application for posting to Mastodon, Bluesky, Nostr, and X (Twitter) simultaneously. Built with Flutter for Linux and Android.

## Features

- Cross-platform support (Linux desktop with system tray, Android mobile)
- Post to multiple platforms simultaneously or individually:
  - **Mastodon** - Decentralized social network (Markdown supported)
  - **Bluesky** - AT Protocol social network
  - **Nostr** - Decentralized protocol with nsec or Android Amber signing
  - **X (Twitter)** - Traditional social media
- Markdown editor with automatic conversion for non-Markdown platforms
- Multiple image support (up to 4 images per post)
- Dark/Light theme support
- Character count tracking per platform
- Persistent credentials storage

## Requirements

### Linux
- Flutter SDK 3.10.4 or later
- GTK 3.0 development headers
- libayatana-appindicator3-dev (for system tray support)

### Android
- Flutter SDK 3.10.4 or later
- Android SDK with API level 21 or higher
- Amber app (optional, for Nostr signing)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/sendit.git
cd sendit
```

2. Install dependencies:
```bash
flutter pub get
```

3. Build for your platform:

**Linux:**
```bash
flutter build linux --release
```

**Android:**
```bash
flutter build apk --release
```

### Pre-built Packages

Download the latest release from the [Releases](https://github.com/yourusername/sendit/releases) page:
- `.deb` package for Debian/Ubuntu-based Linux distributions
- `.apk` for Android devices

## Configuration

On first launch, navigate to Settings and configure API credentials for the platforms you want to use:

### Mastodon
1. Log into your Mastodon instance
2. Go to Settings > Development > New Application
3. Create an application with read/write permissions
4. Enter your instance URL (e.g., `mastodon.social`) and access token in SendIt Settings

### Bluesky
1. Log into Bluesky
2. Go to Settings > App Passwords
3. Generate a new app password
4. Enter your handle (e.g., `username.bsky.social`) and app password in SendIt Settings

### Nostr
**Option 1: Using Amber (Android - Recommended)**
1. Install [Amber](https://github.com/greenart7c3/Amber) from F-Droid or GitHub
2. Import your Nostr key into Amber
3. In SendIt Settings, enter your npub (public key)
4. Enable "Use Amber for signing"
5. When posting, Amber will prompt you to approve each signature
6. SendIt receives the signature via deep link and completes the post

**Option 2: Using nsec (Not Yet Implemented)**
1. Have your Nostr private key (nsec) ready
2. Enter both your npub (public key) and nsec (private key) in SendIt Settings
3. ⚠️ **Note**: Direct nsec signing requires a secp256k1 library (not yet implemented)
4. Currently, you must use Amber on Android for Nostr posting

**Image Privacy**: All images uploaded to Nostr have EXIF data stripped for privacy.

### X (Twitter)
1. Create a Twitter Developer Account and app at https://developer.twitter.com
2. Generate OAuth 1.0a credentials (API Key, API Secret, Access Token, Access Token Secret)
3. Ensure your app has read and write permissions
4. Enter all four credentials in the Settings page

## Usage

1. Write your post in the editor (Markdown supported for Mastodon)
2. Add images if desired (click the image icon)
3. Select which platforms to post to using the filter chips
4. Click "Publish" to post
5. View character counts for each selected platform

### Markdown Support

- **Mastodon**: Full Markdown support
- **Bluesky, Nostr, X**: Markdown is automatically converted to plain text
  - Headers (#, ##, etc.) are stripped
  - Bold/italic formatting is removed
  - Links `[text](url)` are converted to "text url"
  - URLs are counted as 23 characters for X (Twitter's t.co link length)

### Platform Limits
- **Mastodon**: 500 characters (default, varies by instance)
- **Bluesky**: 300 characters
- **Nostr**: No limit
- **X (Twitter)**: 280 characters

### Linux System Tray

On Linux, the app minimizes to the system tray. Right-click the tray icon to:
- Show/Hide the main window
- Quit the application

## Building Packages

### Debian Package (.deb)

Requires `dpkg-deb`:
```bash
flutter build linux --release
cd build/linux/x64/release/bundle
# Create debian package structure and build
```

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```
lib/
├── main.dart              # Application entry point
├── theme.dart             # Theme definitions
├── services/              # Business logic
│   ├── mastodon_service.dart
│   ├── bluesky_service.dart
│   ├── nostr_service.dart
│   ├── x_service.dart
│   ├── posting_service.dart
│   ├── storage_service.dart
│   └── theme_service.dart
└── views/                 # UI components
    ├── compose_view.dart
    └── settings_view.dart
```

## Known Limitations

- **Nostr**: Direct nsec signing requires secp256k1 implementation. Currently works on Android via Amber only.
- **X (Twitter)**: Has rate limits on API calls. The app will display an error if you exceed the daily posting limit.
- **Images**: Limited to 5MB per file for X uploads, 1MB for Bluesky (auto-compressed)
- **Maximum**: 4 images per post across all platforms

## Image Processing

The app automatically processes images for each platform's requirements:
- **Nostr**: EXIF data stripped for privacy (required by nostr.build/blossom.band)
- **Bluesky**: Automatically compressed if over 1MB size limit
- **All platforms**: Maintains image quality while meeting requirements

## Troubleshooting

### Nostr Posts Not Working
**On Android**: Make sure Amber is installed and your key is imported. Enable "Use Amber for signing" in Settings.

**On Desktop**: Direct nsec signing is not yet implemented. A secp256k1 library is required for Schnorr signatures.

### Amber Not Responding
- Ensure Amber app is installed from F-Droid or GitHub
- Check that your Nostr key is properly imported in Amber
- Make sure SendIt has the correct npub (public key) configured
- Try reopening both apps

### Images Not Uploading
- **Nostr**: Check internet connection to nostr.build
- **Bluesky**: Large images are automatically compressed (may take a moment)
- **All platforms**: Ensure images are in supported formats (JPEG, PNG, GIF, WebP)

### Mastodon Instance Not Found
Ensure you enter only the domain without `https://` (e.g., `mastodon.social` not `https://mastodon.social`)

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

Areas where help is appreciated:
- Desktop Nostr support (requires secp256k1 Schnorr signature implementation)
- Additional image hosting options for Nostr
- Unit tests for all services
- Additional platform support

## Support

For issues, questions, or feature requests, please use the GitHub Issues page.

