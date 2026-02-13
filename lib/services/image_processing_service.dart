import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class ImageProcessingService {
  /// Maximum file size for Bluesky (1MB)
  static const int blueskyMaxBytes = 1 * 1024 * 1024;
  
  /// Maximum dimensions for compressed images
  static const int maxWidth = 2048;
  static const int maxHeight = 2048;

  /// Strip EXIF data from image (required for Nostr/blossom.band)
  /// Returns path to processed image
  Future<String> stripExifData(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('ImageProcessing: Failed to decode image');
        return imagePath;
      }

      // Re-encode without EXIF data
      final extension = path.extension(imagePath).toLowerCase();
      Uint8List processedBytes;
      
      switch (extension) {
        case '.png':
          processedBytes = Uint8List.fromList(img.encodePng(image));
          break;
        case '.jpg':
        case '.jpeg':
          processedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
          break;
        case '.webp':
          processedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
          break;
        default:
          processedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 95));
      }

      // Save to temporary file
      final tempDir = await Directory.systemTemp.createTemp('sendit_');
      final processedPath = '${tempDir.path}/processed_${path.basename(imagePath)}';
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(processedBytes);

      debugPrint('ImageProcessing: Stripped EXIF data from $imagePath');
      return processedPath;
    } catch (e) {
      debugPrint('ImageProcessing: Error stripping EXIF: $e');
      return imagePath; // Return original if processing fails
    }
  }

  /// Compress image to fit within size limit (for Bluesky)
  /// Returns path to compressed image
  Future<String> compressForBluesky(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Check if already under limit
      if (bytes.length <= blueskyMaxBytes) {
        debugPrint('ImageProcessing: Image already under Bluesky limit');
        return imagePath;
      }

      debugPrint('ImageProcessing: Compressing image from ${bytes.length} bytes');
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('ImageProcessing: Failed to decode image');
        return imagePath;
      }

      // Resize if too large
      img.Image processedImage = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        processedImage = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
          maintainAspect: true,
        );
      }

      // Compress with progressively lower quality until under limit
      int quality = 85;
      Uint8List compressedBytes;
      
      do {
        compressedBytes = Uint8List.fromList(img.encodeJpg(processedImage, quality: quality));
        debugPrint('ImageProcessing: Trying quality $quality, size: ${compressedBytes.length} bytes');
        
        if (compressedBytes.length <= blueskyMaxBytes) {
          break;
        }
        
        quality -= 10;
        
        // If quality gets too low, resize more aggressively
        if (quality < 50 && processedImage.width > 1024) {
          processedImage = img.copyResize(
            processedImage,
            width: 1024,
            maintainAspect: true,
          );
          quality = 85; // Reset quality after resize
        }
      } while (quality > 20);

      // Save to temporary file
      final tempDir = await Directory.systemTemp.createTemp('sendit_');
      final compressedPath = '${tempDir.path}/compressed_${path.basename(imagePath)}.jpg';
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);

      debugPrint('ImageProcessing: Compressed to ${compressedBytes.length} bytes (quality: $quality)');
      return compressedPath;
    } catch (e) {
      debugPrint('ImageProcessing: Error compressing image: $e');
      return imagePath; // Return original if compression fails
    }
  }

  /// Process image for Nostr: strip EXIF
  Future<String> processForNostr(String imagePath) async {
    return await stripExifData(imagePath);
  }

  /// Process image for Bluesky: compress if needed
  Future<String> processForBluesky(String imagePath) async {
    return await compressForBluesky(imagePath);
  }

  /// Clean up temporary files
  Future<void> cleanupTempFile(String filePath) async {
    try {
      if (filePath.contains('/sendit_')) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('ImageProcessing: Cleaned up temp file: $filePath');
        }
      }
    } catch (e) {
      debugPrint('ImageProcessing: Error cleaning up temp file: $e');
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }
}
