# Changelog

All notable changes to SendIt will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-13

### Fixed
- **CRITICAL: Proper Amber/NIP-55 implementation**
  - Implemented correct NIP-55 protocol for Amber integration
  - App now calls `get_public_key` to retrieve pubkey from Amber
  - No manual npub entry needed when using Amber
  - Proper deep link handling for both `get_public_key` and `sign_event` responses

### Changed
- **Improved Nostr Settings UX**
  - Amber toggle now automatically requests public key from Amber
  - Shows connection status when Amber is connected
  - Manual npub/nsec fields only shown when not using Amber
  - Better error messages for connection issues

### Technical
- Follows NIP-55 Android Signer Application specification
- Amber returns pubkey in hex, converted to npub format
- Deep link callback handles both key exchange and event signing
- Proper separation of Amber vs manual key entry flows

## [1.1.3] - 2026-02-13

### Changed
- **Improved Nostr + Amber UX**
  - Added helper text clarifying npub is required even with Amber
  - Improved error messages explaining Amber only signs (doesn't provide keys)
  - Better validation messaging for Nostr configuration

### Technical Notes
- Amber is a signing-only service - it signs Nostr events but does not provide public keys
- Users must configure their npub in Settings regardless of using Amber or nsec
- The npub is required to create the Nostr event before Amber signs it

## [1.1.2] - 2026-02-13

### Fixed
- **CRITICAL**: Added missing INTERNET permission to AndroidManifest.xml
  - App can now make network requests on Android
  - Fixes "Failed host lookup" errors for all platforms
- Added ACCESS_NETWORK_STATE permission for network connectivity checks

## [1.1.1] - 2026-02-13

### Fixed
- **CRITICAL**: Nostr posting now works with nsec keys
  - Implemented Schnorr signature (BIP-340) using pointycastle
  - Added proper secp256k1 signing for direct nsec usage
  - Fixed early return bug that prevented Amber flow completion
- All platforms can now successfully post without errors

### Added
- `pointycastle` dependency for cryptographic operations

## [1.1.0] - 2026-02-13

### Added
- **Mastodon support** - Full implementation with manual token authentication
  - Instance URL + access token configuration
  - Media upload via v2 API
  - Status posting with full Markdown support
- **Bluesky support** - AT Protocol implementation
  - Handle + app password authentication
  - Automatic image compression for 1MB size limit
  - Progressive quality reduction algorithm
  - Up to 4 images per post
- **Nostr support** - Decentralized protocol implementation
  - Amber integration for secure signing on Android
  - Deep link handling for signature callbacks
  - EXIF data stripping for privacy (nostr.build requirement)
  - Multi-relay publishing (4 default relays)
  - npub/nsec key support
- **Image processing service**
  - EXIF metadata stripping for Nostr uploads
  - Smart compression for Bluesky size limits
  - Automatic temporary file cleanup
  - Format conversion when needed
- **Deep linking** - Android callback support for Amber
  - Custom URI scheme: `sendit://amber_callback`
  - Automatic signature processing
  - User feedback via SnackBar
- **Per-platform character counting**
  - Mastodon: 500 characters
  - Bluesky: 300 characters
  - X: 280 characters (corrected from 300)
  - Nostr: No limit
- **Concurrent multi-platform posting**
  - Posts to all selected platforms simultaneously
  - Individual success/failure tracking
  - Error isolation (one fails, others continue)

### Changed
- Updated compose view to support 4 platforms (was 2)
- Improved Markdown conversion with better regex handling
- Enhanced settings page with all platform configurations
- Updated README with comprehensive documentation
- Improved error messages and user feedback
- Better character counting with platform-specific logic

### Removed
- **Micro.blog support** - Completely removed
  - Service deleted
  - UI elements removed
  - Storage keys cleaned up

### Fixed
- X (Twitter) character limit corrected to 280 (was incorrectly 300)
- Improved bold/italic Markdown stripping to handle nested formatting
- Better URL handling in character counting

### Security
- EXIF data automatically stripped from Nostr uploads
- Amber integration keeps private keys secure (never exposed to SendIt)
- Obscured text fields for all credential inputs

### Technical
- Added 7 new dependencies (image, bech32, web_socket_channel, etc.)
- Created 4 new service files
- Modified 8 existing files
- Total codebase: 2,314 lines (+970 lines, +72%)
- Android manifest updated with deep link intent filters

### Known Limitations
- Desktop Nostr requires secp256k1 library (not implemented)
- Nostr works on Android via Amber only
- Credentials stored in SharedPreferences (consider encryption upgrade)

## [1.0.0] - Initial Release

### Added
- Initial release with Micro.blog and X (Twitter) support
- Basic Markdown editor
- Image upload support
- Linux system tray integration
- Theme support (Nord, Parchment, Newspaper)
- Cross-platform support (Linux, Android)
