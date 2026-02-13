import 'package:flutter/foundation.dart';
import 'mastodon_service.dart';
import 'bluesky_service.dart';
import 'nostr_service.dart';
import 'x_service.dart';

class PostingService extends ChangeNotifier {
  MastodonService mastodonService;
  BlueskyService blueskyService;
  NostrService nostrService;
  XService xService;

  PostingService({
    required this.mastodonService,
    required this.blueskyService,
    required this.nostrService,
    required this.xService,
  });

  void update(MastodonService mastodon, BlueskyService bluesky, NostrService nostr, XService x) {
    mastodonService = mastodon;
    blueskyService = bluesky;
    nostrService = nostr;
    xService = x;
    notifyListeners();
  }

  bool _isPosting = false;
  bool get isPosting => _isPosting;

  /// Post to selected services simultaneously
  Future<Map<String, dynamic>> postAll(
    String markdownContent,
    List<String> imagePaths, {
    bool postToMastodon = false,
    bool postToBluesky = false,
    bool postToNostr = false,
    bool postToX = false,
  }) async {
    _isPosting = true;
    notifyListeners();

    final results = <String, dynamic>{
      'mastodon': postToMastodon ? null : 'Skipped',
      'bluesky': postToBluesky ? null : 'Skipped',
      'nostr': postToNostr ? null : 'Skipped',
      'x': postToX ? null : 'Skipped',
    };

    try {
      final futures = <Future>[];
      
      // Mastodon supports Markdown natively
      if (postToMastodon) {
        futures.add(
          mastodonService.post(markdownContent, imagePaths: imagePaths).then((_) {
            results['mastodon'] = 'Success';
          }).catchError((e) {
            results['mastodon'] = 'Error: $e';
          }),
        );
      }
      
      // Bluesky uses plain text
      if (postToBluesky) {
        final blueskyContent = stripMarkdownForPlainText(markdownContent);
        futures.add(
          blueskyService.post(blueskyContent, imagePaths: imagePaths).then((_) {
            results['bluesky'] = 'Success';
          }).catchError((e) {
            results['bluesky'] = 'Error: $e';
          }),
        );
      }
      
      // Nostr uses plain text with URLs
      if (postToNostr) {
        final nostrContent = stripMarkdownForPlainText(markdownContent);
        futures.add(
          nostrService.post(nostrContent, imagePaths: imagePaths).then((_) {
            results['nostr'] = 'Success';
          }).catchError((e) {
            results['nostr'] = 'Error: $e';
          }),
        );
      }
      
      // X (Twitter) uses plain text
      if (postToX) {
        final xContent = stripMarkdownForPlainText(markdownContent);
        futures.add(
          xService.post(xContent, imagePaths: imagePaths).then((_) {
            results['x'] = 'Success';
          }).catchError((e) {
            results['x'] = 'Error: $e';
          }),
        );
      }
      
      await Future.wait(futures);
    } catch (e) {
      debugPrint('Critical error in postAll: $e');
    } finally {
      _isPosting = false;
      notifyListeners();
    }

    return results;
  }

  /// Strips Markdown syntax for plain text platforms (X, Bluesky, Nostr)
  String stripMarkdownForPlainText(String markdown) {
    String text = markdown;

    // Remove headers (#, ##, etc.)
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // Remove bold/italic (**text**, __text__, *text*, _text_)
    text = text.replaceAll(RegExp(r'\*\*([^\*]+)\*\*'), r'$1'); // Bold **
    text = text.replaceAll(RegExp(r'__([^_]+)__'), r'$1');       // Bold __
    text = text.replaceAll(RegExp(r'\*([^\*]+)\*'), r'$1');      // Italic *
    text = text.replaceAll(RegExp(r'_([^_]+)_'), r'$1');         // Italic _

    // Replace links [text](url) with "text url"
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (match) {
      final linkText = match.group(1);
      final url = match.group(2);
      return '$linkText $url';
    });

    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[^`]*```'), '');
    text = text.replaceAll('`', '');

    // Remove blockquotes
    text = text.replaceAll(RegExp(r'^\s*>\s*', multiLine: true), '');

    return text.trim();
  }

  /// Calculates character count for X (Twitter).
  /// URLs are counted as 23 characters.
  int calculateXLength(String text) {
    int length = 0;
    
    // Regex to find URLs
    final urlRegExp = RegExp(r'https?:\/\/\S+');
    final matches = urlRegExp.allMatches(text);

    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add length of text before this URL
      length += text.substring(lastMatchEnd, match.start).length;
      // Add 23 for the URL
      length += 23;
      lastMatchEnd = match.end;
    }

    // Add remaining text
    length += text.substring(lastMatchEnd).length;

    return length;
  }

  /// Get character limits for each platform
  Map<String, int> getCharacterLimits() {
    return {
      'mastodon': 500,  // Default, can vary by instance
      'bluesky': 300,
      'nostr': 0,       // No limit
      'x': 280,
    };
  }
}

