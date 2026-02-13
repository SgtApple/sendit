import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'image_processing_service.dart';

class BlueskyService extends ChangeNotifier {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();
  final ImageProcessingService _imageProcessing = ImageProcessingService();

  static const String _apiBase = 'https://bsky.social/xrpc';
  
  String? _accessJwt;
  String? _did;

  Future<void> _authenticate() async {
    final identifier = await _storage.getString(StorageService.keyBlueskyIdentifier);
    final password = await _storage.getString(StorageService.keyBlueskyPassword);

    if (identifier == null || identifier.isEmpty || password == null || password.isEmpty) {
      throw Exception('Bluesky credentials not configured');
    }

    try {
      final response = await _dio.post(
        '$_apiBase/com.atproto.server.createSession',
        data: {
          'identifier': identifier,
          'password': password,
        },
      );

      _accessJwt = response.data['accessJwt'];
      _did = response.data['did'];
      debugPrint('Bluesky: Authenticated as $_did');
    } on DioException catch (e) {
      debugPrint('Bluesky auth error: ${e.response?.data}');
      throw Exception('Bluesky authentication failed: ${e.response?.data?['message'] ?? e.message}');
    }
  }

  /// Upload blob (image) to Bluesky with compression if needed
  Future<Map<String, dynamic>?> _uploadBlob(String imagePath) async {
    if (_accessJwt == null) {
      await _authenticate();
    }

    // Compress image if needed for Bluesky's size limit
    final processedPath = await _imageProcessing.processForBluesky(imagePath);
    
    final file = File(processedPath);
    if (!await file.exists()) {
      debugPrint('Bluesky: File does not exist: $processedPath');
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      debugPrint('Bluesky: Uploading blob, size: ${bytes.length} bytes');
      
      // Determine mime type
      final extension = imagePath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      final response = await _dio.post(
        '$_apiBase/com.atproto.repo.uploadBlob',
        data: bytes,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessJwt',
            'Content-Type': mimeType,
          },
        ),
      );

      debugPrint('Bluesky: Blob uploaded: ${response.data}');
      
      // Clean up temp file if it was processed
      if (processedPath != imagePath) {
        await _imageProcessing.cleanupTempFile(processedPath);
      }
      
      return response.data['blob'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Bluesky: Blob upload error: $e');
      // Clean up temp file on error
      if (processedPath != imagePath) {
        await _imageProcessing.cleanupTempFile(processedPath);
      }
      return null;
    }
  }

  Future<void> post(String content, {List<String>? imagePaths}) async {
    if (_accessJwt == null || _did == null) {
      await _authenticate();
    }

    debugPrint('Bluesky: Creating post...');

    // Upload images first
    List<Map<String, dynamic>> images = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths.take(4)) { // Bluesky supports up to 4 images
        final blob = await _uploadBlob(path);
        if (blob != null) {
          images.add({
            'alt': '',
            'image': blob,
          });
        }
      }
    }

    // Build post record
    final record = <String, dynamic>{
      '\$type': 'app.bsky.feed.post',
      'text': content,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    // Add images as embed if present
    if (images.isNotEmpty) {
      record['embed'] = {
        '\$type': 'app.bsky.embed.images',
        'images': images,
      };
    }

    try {
      final response = await _dio.post(
        '$_apiBase/com.atproto.repo.createRecord',
        data: {
          'repo': _did,
          'collection': 'app.bsky.feed.post',
          'record': record,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessJwt',
            'Content-Type': 'application/json',
          },
        ),
      );
      debugPrint('Bluesky: Post created: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('Bluesky error: ${e.response?.statusCode}');
      debugPrint('Bluesky error body: ${e.response?.data}');
      rethrow;
    }
  }
}
