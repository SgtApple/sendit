import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class XService extends ChangeNotifier {
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  static const String _tweetEndpoint = 'https://api.twitter.com/2/tweets';
  static const String _mediaUploadEndpoint = 'https://upload.twitter.com/1.1/media/upload.json';

  /// Generate OAuth 1.0a signature
  String _generateSignature(
    String method,
    String url,
    Map<String, String> params,
    String consumerSecret,
    String tokenSecret,
  ) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    
    final paramString = sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final signatureBase = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');
    
    debugPrint('X: Signature base string: $signatureBase');
    
    final signingKey = '${Uri.encodeComponent(consumerSecret)}&${Uri.encodeComponent(tokenSecret)}';
    
    final hmac = Hmac(sha1, utf8.encode(signingKey));
    final digest = hmac.convert(utf8.encode(signatureBase));
    
    return base64.encode(digest.bytes);
  }

  /// Generate OAuth 1.0a Authorization header
  Future<String> _getOAuthHeader(String method, String url, {Map<String, String>? additionalParams}) async {
    final apiKey = await _storage.getString(StorageService.keyXApiKey) ?? '';
    final apiSecret = await _storage.getString(StorageService.keyXApiSecret) ?? '';
    final userToken = await _storage.getString(StorageService.keyXUserToken) ?? '';
    final userSecret = await _storage.getString(StorageService.keyXUserSecret) ?? '';

    if (apiKey.isEmpty || apiSecret.isEmpty || userToken.isEmpty || userSecret.isEmpty) {
      throw Exception('X (Twitter) credentials not configured');
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final nonce = _generateNonce();

    final oauthParams = <String, String>{
      'oauth_consumer_key': apiKey,
      'oauth_nonce': nonce,
      'oauth_signature_method': 'HMAC-SHA1',
      'oauth_timestamp': timestamp,
      'oauth_token': userToken,
      'oauth_version': '1.0',
    };

    final allParams = {...oauthParams, ...?additionalParams};
    final signature = _generateSignature(method, url, allParams, apiSecret, userSecret);
    oauthParams['oauth_signature'] = signature;

    final headerParts = oauthParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}="${Uri.encodeComponent(e.value)}"')
        .join(', ');

    return 'OAuth $headerParts';
  }

  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(values).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Upload media to Twitter using chunked upload API
  /// INIT -> APPEND -> FINALIZE (all form-urlencoded, no multipart)
  Future<String?> _uploadMedia(String imagePath) async {
    debugPrint('X: Uploading media: $imagePath');
    final file = File(imagePath);
    
    if (!await file.exists()) {
      debugPrint('X: File does not exist: $imagePath');
      return null;
    }
    
    try {
      final bytes = await file.readAsBytes();
      final totalBytes = bytes.length;
      debugPrint('X: File size: $totalBytes bytes');
      
      // Check file size (5MB limit for images)
      if (totalBytes > 5 * 1024 * 1024) {
        debugPrint('X: File too large for upload');
        return null;
      }

      // Determine media type
      final extension = imagePath.split('.').last.toLowerCase();
      String mediaType;
      switch (extension) {
        case 'png':
          mediaType = 'image/png';
          break;
        case 'gif':
          mediaType = 'image/gif';
          break;
        case 'webp':
          mediaType = 'image/webp';
          break;
        default:
          mediaType = 'image/jpeg';
      }

      // STEP 1: INIT
      debugPrint('X: INIT - Starting chunked upload...');
      final initParams = {
        'command': 'INIT',
        'total_bytes': totalBytes.toString(),
        'media_type': mediaType,
      };
      
      final initAuthHeader = await _getOAuthHeader('POST', _mediaUploadEndpoint, additionalParams: initParams);
      
      final initResponse = await http.post(
        Uri.parse(_mediaUploadEndpoint),
        headers: {
          'Authorization': initAuthHeader,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: initParams,
      );
      
      debugPrint('X: INIT response status: ${initResponse.statusCode}');
      debugPrint('X: INIT response body: ${initResponse.body}');
      
      if (initResponse.statusCode != 200 && initResponse.statusCode != 202) {
        debugPrint('X: INIT failed');
        return null;
      }
      
      final initData = jsonDecode(initResponse.body);
      final mediaId = initData['media_id_string'] as String;
      debugPrint('X: Got media_id: $mediaId');

      // STEP 2: APPEND - Send data as multipart (Twitter requires this for media_data)
      debugPrint('X: APPEND - Uploading data...');
      
      // Try base64 approach instead of multipart
      final mediaData = base64Encode(bytes);
      
      // For APPEND with base64, include media_data in signature
      final appendSignatureParams = {
        'command': 'APPEND',
        'media_data': mediaData,
        'media_id': mediaId,
        'segment_index': '0',
      };
      
      final appendAuthHeader = await _getOAuthHeader('POST', _mediaUploadEndpoint, additionalParams: appendSignatureParams);
      
      // Use form-urlencoded instead of multipart
      final appendResponse = await http.post(
        Uri.parse(_mediaUploadEndpoint),
        headers: {
          'Authorization': appendAuthHeader,
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'SendIt/1.0',
        },
        body: {
          'command': 'APPEND',
          'media_data': mediaData,
          'media_id': mediaId,
          'segment_index': '0',
        },
      );
      
      debugPrint('X: APPEND response status: ${appendResponse.statusCode}');
      debugPrint('X: APPEND response body: ${appendResponse.body}');
      
      // APPEND returns 204 No Content on success, or 200/202
      if (appendResponse.statusCode != 200 && 
          appendResponse.statusCode != 202 && 
          appendResponse.statusCode != 204) {
        debugPrint('X: APPEND failed');
        return null;
      }

      // STEP 3: FINALIZE
      debugPrint('X: FINALIZE - Completing upload...');
      final finalizeParams = {
        'command': 'FINALIZE',
        'media_id': mediaId,
      };
      
      final finalizeAuthHeader = await _getOAuthHeader('POST', _mediaUploadEndpoint, additionalParams: finalizeParams);
      
      final finalizeResponse = await http.post(
        Uri.parse(_mediaUploadEndpoint),
        headers: {
          'Authorization': finalizeAuthHeader,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: finalizeParams,
      );
      
      debugPrint('X: FINALIZE response status: ${finalizeResponse.statusCode}');
      debugPrint('X: FINALIZE response body: ${finalizeResponse.body}');
      
      if (finalizeResponse.statusCode != 200 && finalizeResponse.statusCode != 201) {
        debugPrint('X: FINALIZE failed');
        return null;
      }
      
      debugPrint('X: ✓ Media uploaded successfully! ID: $mediaId');
      return mediaId;
    } catch (e) {
      debugPrint('X: Media upload error: $e');
      return null;
    }
  }

  Future<void> post(String content, {List<String>? imagePaths}) async {
    debugPrint('X: Starting post...');
    
    // Upload images first
    List<String> mediaIds = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        try {
          debugPrint('X: Uploading media: $path');
          final mediaId = await _uploadMedia(path);
          if (mediaId != null) {
            mediaIds.add(mediaId);
            debugPrint('X: Got media ID: $mediaId');
          }
        } catch (e) {
          debugPrint('X: Failed to upload media: $e');
          // Continue without this image rather than failing completely
        }
      }
    }

    // Build tweet payload
    final Map<String, dynamic> tweetData = {
      'text': content,
    };

    if (mediaIds.isNotEmpty) {
      tweetData['media'] = {
        'media_ids': mediaIds,
      };
    }

    final authHeader = await _getOAuthHeader('POST', _tweetEndpoint);
    debugPrint('X: Auth header: $authHeader');
    debugPrint('X: Tweet data: ${jsonEncode(tweetData)}');

    try {
      final response = await _dio.post(
        _tweetEndpoint,
        data: jsonEncode(tweetData),
        options: Options(
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/json',
          },
        ),
      );
      debugPrint('X response: ${response.statusCode}');
      debugPrint('X response body: ${response.data}');
    } on DioException catch (e) {
      debugPrint('X error: ${e.response?.statusCode}');
      debugPrint('X error body: ${e.response?.data}');
      debugPrint('X error headers: ${e.response?.headers}');

      if (e.response?.statusCode == 429) {
        final resetTime = e.response?.headers.value('x-rate-limit-reset');
        throw Exception('X (Twitter) Rate Limit Exceeded (429). Daily limit reached. Resets at timestamp $resetTime');
      }
      rethrow;
    }
  }
}
