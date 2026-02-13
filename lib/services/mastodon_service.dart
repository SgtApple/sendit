import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class MastodonService extends ChangeNotifier {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  Future<String?> _getInstance() async {
    return await _storage.getString(StorageService.keyMastodonInstance);
  }

  Future<String?> _getToken() async {
    return await _storage.getString(StorageService.keyMastodonToken);
  }

  /// Upload media to Mastodon
  Future<String?> _uploadMedia(String imagePath, String instance, String token) async {
    final file = File(imagePath);
    
    if (!await file.exists()) {
      debugPrint('Mastodon: File does not exist: $imagePath');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: file.uri.pathSegments.last,
        ),
      });

      final response = await _dio.post(
        'https://$instance/api/v2/media',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      debugPrint('Mastodon: Media uploaded: ${response.data}');
      return response.data['id'] as String?;
    } catch (e) {
      debugPrint('Mastodon: Media upload error: $e');
      return null;
    }
  }

  Future<void> post(String content, {List<String>? imagePaths}) async {
    final instance = await _getInstance();
    final token = await _getToken();

    if (instance == null || instance.isEmpty || token == null || token.isEmpty) {
      throw Exception('Mastodon credentials not configured');
    }

    debugPrint('Mastodon: Posting to instance: $instance');

    // Upload media first
    List<String> mediaIds = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        final mediaId = await _uploadMedia(path, instance, token);
        if (mediaId != null) {
          mediaIds.add(mediaId);
        }
      }
    }

    // Create status
    final data = <String, dynamic>{
      'status': content,
    };

    if (mediaIds.isNotEmpty) {
      data['media_ids'] = mediaIds;
    }

    try {
      final response = await _dio.post(
        'https://$instance/api/v1/statuses',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      debugPrint('Mastodon: Post created: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('Mastodon error: ${e.response?.statusCode}');
      debugPrint('Mastodon error body: ${e.response?.data}');
      rethrow;
    }
  }
}
