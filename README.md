# SendIt

A minimalist cross-platform application for posting to Micro.blog and X (Twitter) simultaneously. Built with Flutter for Linux and Android.

## Features

- Cross-platform support (Linux desktop with system tray, Android mobile)
- Markdown editor with automatic conversion for X/Twitter
- Multiple image support (up to 4 images per post)
- Post to both platforms simultaneously or individually
- Dark/Light theme support
- Character count tracking for X/Twitter (with URL shortening calculation)
- Persistent credentials storage

## Requirements

### Linux
- Flutter SDK 3.10.4 or later
- GTK 3.0 development headers
- libayatana-appindicator3-dev (for system tray support)

### Android
- Flutter SDK 3.10.4 or later
- Android SDK with API level 21 or higher

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

On first launch, navigate to Settings and configure your API credentials:

### Micro.blog
1. Generate an App Token from Micro.blog Settings > App Tokens
2. Enter your token and Micro.blog hostname (e.g., `yourblog.micro.blog`)

### X (Twitter)
1. Create a Twitter Developer Account and app at https://developer.twitter.com
2. Generate OAuth 1.0a credentials (API Key, API Secret, Access Token, Access Token Secret)
3. Ensure your app has read and write permissions
4. Enter all four credentials in the Settings page

## Usage

1. Write your post in the Markdown editor
2. Add images if desired (click the image icon)
3. Select which platforms to post to (Micro.blog, X, or both)
4. Click "Publish" to post

### Markdown Support

The editor supports standard Markdown syntax. When posting to X, Markdown formatting is automatically converted:
- Headers (#, ##, etc.) are stripped
- Bold/italic formatting is removed
- Links `[text](url)` are converted to "text url"
- URLs are counted as 23 characters (Twitter's t.co link length)

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
│   ├── microblog_service.dart
│   ├── x_service.dart
│   ├── posting_service.dart
│   ├── storage_service.dart
│   └── theme_service.dart
└── views/                 # UI components
    ├── compose_view.dart
    └── settings_view.dart
```

## Known Limitations

- X (Twitter) has rate limits on API calls. The app will display an error if you exceed the daily posting limit.
- Images are limited to 5MB per file for X uploads
- Maximum of 4 images per post

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome. Please open an issue or submit a pull request.

## Support

For issues, questions, or feature requests, please use the GitHub Issues page.
