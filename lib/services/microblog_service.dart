import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class MicroBlogService extends ChangeNotifier {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  static const String _micropubEndpoint = 'https://micro.blog/micropub';
  static const String _mediaEndpoint = 'https://micro.blog/micropub/media';

  Future<String?> _getToken() async {
    return await _storage.getString(StorageService.keyMicroBlogToken);
  }

  /// Upload an image to Micro.blog and return its URL
  Future<String?> _uploadImage(String imagePath) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Micro.blog token not configured');
    }

    final file = File(imagePath);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imagePath,
        filename: file.uri.pathSegments.last,
      ),
    });

    final response = await _dio.post(
      _mediaEndpoint,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    // Micro.blog returns the URL in the Location header
    return response.headers.value('location');
  }

  Future<void> post(String content, {List<String>? imagePaths}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Micro.blog token not configured');
    }

    // Upload images first and collect URLs
    List<String> imageUrls = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        final url = await _uploadImage(path);
        if (url != null) {
          imageUrls.add(url);
        }
      }
    }

    // Build the post content with images
    String finalContent = content;
    for (final url in imageUrls) {
      finalContent += '\n\n![]($url)';
    }

    // Create the post via Micropub using FormData (like MB-Manager)
    debugPrint('Micro.blog: Posting to $_micropubEndpoint');
    debugPrint('Micro.blog: Token length: ${token.length}');
    debugPrint('Micro.blog: Content: $finalContent');
    
    // Build form data map matching MB-Manager's approach
    final formMap = <String, dynamic>{
      'h': 'entry',
      'content': finalContent,
    };
    
    final formData = FormData.fromMap(formMap);
    
    try {
      final response = await _dio.post(
        _micropubEndpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      debugPrint('Micro.blog response: ${response.statusCode}');
      debugPrint('Micro.blog response body: ${response.data}');
    } on DioException catch (e) {
      debugPrint('Micro.blog error: ${e.response?.statusCode}');
      debugPrint('Micro.blog error body: ${e.response?.data}');
      debugPrint('Micro.blog error headers: ${e.response?.headers}');
      rethrow;
    }
  }
}
