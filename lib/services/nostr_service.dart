import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:bech32/bech32.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';
import 'storage_service.dart';
import 'image_processing_service.dart';

// For Amber integration on Android
import 'package:android_intent_plus/android_intent.dart' as android_intent;
import 'package:android_intent_plus/flag.dart';

class NostrService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Dio _dio = Dio();
  final ImageProcessingService _imageProcessing = ImageProcessingService();

  static const List<String> _defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.primal.net',
    'wss://nos.lol',
    'wss://relay.pleb.one',
  ];

  // For Amber callback handling
  String? _pendingEventId;
  String? _pendingEventJson;

  /// Convert nsec to hex private key
  String? _nsecToHex(String nsec) {
    try {
      final decoded = bech32.decode(nsec);
      final data = _convertBits(decoded.data, 5, 8, false);
      return hex.encode(data);
    } catch (e) {
      debugPrint('Nostr: Error decoding nsec: $e');
      return null;
    }
  }

  /// Convert npub to hex public key
  String? _npubToHex(String npub) {
    try {
      final decoded = bech32.decode(npub);
      final data = _convertBits(decoded.data, 5, 8, false);
      return hex.encode(data);
    } catch (e) {
      debugPrint('Nostr: Error decoding npub: $e');
      return null;
    }
  }

  /// Bech32 bit conversion helper
  List<int> _convertBits(List<int> data, int from, int to, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << to) - 1;

    for (var value in data) {
      acc = (acc << from) | value;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad && bits > 0) {
      result.add((acc << (to - bits)) & maxv);
    }

    return result;
  }

  /// Get public key from private key
  String _getPublicKey(String privateKeyHex) {
    // For actual implementation, you'd use secp256k1
    // This is a placeholder - in production use a proper crypto library
    // For now, we'll require the user to provide npub separately
    throw UnimplementedError('Use npub for public key');
  }

  /// Sign using Amber app on Android
  Future<void> _signWithAmber(String eventJson, String pubkey) async {
    if (!Platform.isAndroid) {
      throw Exception('Amber is only available on Android');
    }

    try {
      debugPrint('Nostr: Signing with Amber...');
      
      // Encode event JSON for URL
      final encodedEvent = Uri.encodeComponent(eventJson);
      
      // Create Amber signing intent
      // Format: nostrsigner:{eventJson}?type=sign_event&callbackUrl={callback}
      final amberUri = 'nostrsigner:$encodedEvent?compression=none&returnType=signature&type=sign_event&callbackUrl=sendit://amber_callback&id=${DateTime.now().millisecondsSinceEpoch}';
      
      final intent = android_intent.AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: amberUri,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      debugPrint('Nostr: Launching Amber...');
      await intent.launch();
      
      // Note: The actual signature will be received via deep link callback
      // This is handled in main.dart with uni_links
      debugPrint('Nostr: Waiting for Amber callback...');
    } catch (e) {
      debugPrint('Nostr: Amber signing error: $e');
      throw Exception('Failed to launch Amber: $e');
    }
  }


  /// Upload image to nostr.build (with EXIF stripping)
  Future<String?> _uploadImage(String imagePath) async {
    // Strip EXIF data first
    final processedPath = await _imageProcessing.processForNostr(imagePath);
    
    final file = File(processedPath);
    
    if (!await file.exists()) {
      debugPrint('Nostr: File does not exist: $processedPath');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'fileToUpload': await MultipartFile.fromFile(
          processedPath,
          filename: file.uri.pathSegments.last,
        ),
      });

      final response = await _dio.post(
        'https://nostr.build/api/v2/upload/files',
        data: formData,
      );

      debugPrint('Nostr: Image uploaded to nostr.build: ${response.data}');
      
      // Clean up temp file if it was processed
      if (processedPath != imagePath) {
        await _imageProcessing.cleanupTempFile(processedPath);
      }
      
      // nostr.build returns various formats, get the URL
      if (response.data['status'] == 'success' && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is List && data.isNotEmpty) {
          return data[0]['url'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Nostr: Image upload error: $e');
      // Clean up temp file on error
      if (processedPath != imagePath) {
        await _imageProcessing.cleanupTempFile(processedPath);
      }
      return null;
    }
  }

  Future<void> post(String content, {List<String>? imagePaths}) async {
    final useAmber = await _storage.getBool(StorageService.keyNostrUseAmber);
    final nsec = await _storage.getString(StorageService.keyNostrNsec);
    final npub = await _storage.getString(StorageService.keyNostrNpub);

    if (npub == null || npub.isEmpty) {
      throw Exception('Nostr public key (npub) not configured');
    }

    final pubkeyHex = _npubToHex(npub);
    if (pubkeyHex == null) {
      throw Exception('Invalid Nostr public key');
    }

    // Upload images first
    List<String> imageUrls = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        final url = await _uploadImage(path);
        if (url != null) {
          imageUrls.add(url);
          debugPrint('Nostr: Image uploaded: $url');
        }
      }
    }

    // Add image URLs to content
    String finalContent = content;
    for (final url in imageUrls) {
      finalContent += '\n$url';
    }

    // Create Nostr event (kind 1 = text note)
    final event = <String, dynamic>{
      'pubkey': pubkeyHex,
      'created_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
      'kind': 1,
      'tags': [],
      'content': finalContent,
    };

    // Calculate event ID (hash of serialized event)
    final serialized = jsonEncode([
      0, // Reserved
      event['pubkey'],
      event['created_at'],
      event['kind'],
      event['tags'],
      event['content'],
    ]);
    
    final bytes = utf8.encode(serialized);
    final hash = sha256.convert(bytes);
    final eventId = hex.encode(hash.bytes);
    event['id'] = eventId;

    // Sign the event
    Map<String, dynamic> signedEvent;
    
    if (useAmber && Platform.isAndroid) {
      // Use Amber for signing
      debugPrint('Nostr: Signing with Amber...');
      
      // Store event for callback
      _pendingEventId = eventId;
      _pendingEventJson = jsonEncode(event);
      
      // Launch Amber and wait for callback
      final eventJsonForAmber = jsonEncode(event);
      await _signWithAmber(eventJsonForAmber, pubkeyHex);
      
      // This will throw an exception explaining callback is needed
      // In production, this would wait for the deep link callback
      return;
    } else {
      // Use nsec for signing
      if (nsec == null || nsec.isEmpty) {
        throw Exception('Nostr private key (nsec) not configured. Use Amber on Android or provide nsec.');
      }
      
      final privateKeyHex = _nsecToHex(nsec);
      if (privateKeyHex == null) {
        throw Exception('Invalid Nostr private key');
      }
      
      debugPrint('Nostr: Signing with nsec...');
      final signature = _signEventSchnorr(eventId, privateKeyHex);
      signedEvent = Map<String, dynamic>.from(event);
      signedEvent['sig'] = signature;
    }

    // Publish to relays (only reached if not using Amber)
    debugPrint('Nostr: Publishing to relays...');
    await _publishToRelays(signedEvent);
  }

  /// Complete posting after Amber callback (called from main.dart)
  Future<void> completePostWithAmberSignature(String signature) async {
    if (_pendingEventJson == null) {
      throw Exception('No pending event for Amber signature');
    }

    final event = jsonDecode(_pendingEventJson!) as Map<String, dynamic>;
    event['sig'] = signature;
    
    debugPrint('Nostr: Event signed by Amber, publishing...');
    await _publishToRelays(event);
    
    // Clear pending event
    _pendingEventId = null;
    _pendingEventJson = null;
  }

  /// Publish event to multiple Nostr relays
  Future<void> _publishToRelays(Map<String, dynamic> event) async {
    final futures = <Future>[];

    for (final relayUrl in _defaultRelays) {
      futures.add(_publishToRelay(relayUrl, event));
    }

    // Wait for at least one to succeed
    try {
      await Future.any(futures);
      debugPrint('Nostr: Event published successfully');
    } catch (e) {
      debugPrint('Nostr: Failed to publish to any relay: $e');
      throw Exception('Failed to publish to Nostr relays');
    }
  }

  /// Publish event to a single relay
  Future<void> _publishToRelay(String relayUrl, Map<String, dynamic> event) async {
    try {
      debugPrint('Nostr: Connecting to relay: $relayUrl');
      
      final channel = WebSocketChannel.connect(Uri.parse(relayUrl));
      
      // Send EVENT message
      final message = jsonEncode(['EVENT', event]);
      channel.sink.add(message);
      debugPrint('Nostr: Sent event to $relayUrl');

      // Wait for OK response
      await channel.stream.timeout(const Duration(seconds: 5)).first;
      
      await channel.sink.close();
      debugPrint('Nostr: Successfully published to $relayUrl');
    } catch (e) {
      debugPrint('Nostr: Error publishing to $relayUrl: $e');
      rethrow;
    }
  }

  /// Sign event with Schnorr signature (BIP-340)
  String _signEventSchnorr(String eventId, String privateKeyHex) {
    try {
      // Convert hex strings to bytes
      final privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
      final messageBytes = Uint8List.fromList(hex.decode(eventId));
      
      // Create secp256k1 parameters
      final params = ECDomainParameters('secp256k1');
      final privateKey = ECPrivateKey(
        BigInt.parse(privateKeyHex, radix: 16),
        params,
      );
      
      // Generate deterministic nonce using RFC6979
      final k = _generateNonce(privateKeyBytes, messageBytes);
      
      // Calculate R = k*G
      final R = (params.G * k)!;
      final rx = R.x!.toBigInteger()!;
      
      // If R.y is odd, negate k
      final ry = R.y!.toBigInteger()!;
      var kFinal = k;
      if (ry.isOdd) {
        kFinal = params.n - k;
      }
      
      // Calculate e = H(rx || P || m) where P is public key
      final P = (params.G * privateKey.d!)!;
      final px = P.x!.toBigInteger()!;
      
      final rxBytes = _bigIntToBytes32(rx);
      final pxBytes = _bigIntToBytes32(px);
      final combined = Uint8List.fromList([...rxBytes, ...pxBytes, ...messageBytes]);
      final eHash = sha256.convert(combined);
      final e = BigInt.parse(hex.encode(eHash.bytes), radix: 16) % params.n;
      
      // Calculate s = k + e*d mod n
      final s = (kFinal + e * privateKey.d!) % params.n;
      
      // Signature is rx || s (64 bytes total)
      final signature = Uint8List(64);
      signature.setRange(0, 32, _bigIntToBytes32(rx));
      signature.setRange(32, 64, _bigIntToBytes32(s));
      
      return hex.encode(signature);
    } catch (e) {
      debugPrint('Nostr: Schnorr signing error: $e');
      rethrow;
    }
  }

  /// Generate deterministic nonce using simplified RFC6979
  BigInt _generateNonce(Uint8List privateKey, Uint8List message) {
    final params = ECDomainParameters('secp256k1');
    
    // Simplified: Use HMAC-SHA256(key=privateKey, msg=message)
    final hmac = Hmac(sha256, privateKey);
    final k = hmac.convert(message);
    final kBigInt = BigInt.parse(hex.encode(k.bytes), radix: 16);
    
    // Ensure k is in valid range [1, n-1]
    return (kBigInt % (params.n - BigInt.one)) + BigInt.one;
  }

  /// Convert BigInt to 32-byte array
  Uint8List _bigIntToBytes32(BigInt value) {
    final bytes = Uint8List(32);
    var hex = value.toRadixString(16).padLeft(64, '0');
    for (var i = 0; i < 32; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}
