import 'package:flutter/foundation.dart';
import 'microblog_service.dart';
import 'x_service.dart';

class PostingService extends ChangeNotifier {
  MicroBlogService microBlogService;
  XService xService;

  PostingService({required this.microBlogService, required this.xService});

  void update(MicroBlogService microBlog, XService x) {
    microBlogService = microBlog;
    xService = x;
    notifyListeners();
  }

  bool _isPosting = false;
  bool get isPosting => _isPosting;

  /// Post to selected services simultaneously
  Future<Map<String, dynamic>> postAll(
    String markdownContent,
    List<String> imagePaths, {
    bool postToMicroblog = true,
    bool postToX = true,
  }) async {
    _isPosting = true;
    notifyListeners();

    final xContent = stripMarkdownForX(markdownContent);
    final results = <String, dynamic>{
      'microblog': postToMicroblog ? null : 'Skipped',
      'x': postToX ? null : 'Skipped',
    };

    try {
      final futures = <Future>[];
      
      if (postToMicroblog) {
        futures.add(
          microBlogService.post(markdownContent, imagePaths: imagePaths).then((_) {
            results['microblog'] = 'Success';
          }).catchError((e) {
            results['microblog'] = 'Error: $e';
          }),
        );
      }
      
      if (postToX) {
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

  /// Strips Markdown syntax for X (Twitter) while preserving links and text.
  String stripMarkdownForX(String markdown) {
    String text = markdown;

    // Remove headers (#, ##, etc.)
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // Remove bold/italic (**text**, __text__, *text*, _text_)
    // Note: handling nested might be tricky with regex, simple approach:
    text = text.replaceAll(RegExp(r'(\*\*|__)'), ''); // Start/End bold
    text = text.replaceAll(RegExp(r'(\*|_)'), '');    // Start/End italic

    // Replace links [text](url) with "text url"
    // Use a regex to capture text and url
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (match) {
      final linkText = match.group(1);
      final url = match.group(2);
      return '$linkText $url';
    });

    // Remove code blocks (optional, but good for cleanup)
    text = text.replaceAll('```', '');
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
}
