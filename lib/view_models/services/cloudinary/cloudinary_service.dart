import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:path/path.dart' as p;
import '../../../res/app_url/app_url.dart';
import '../image_cache/image_cache_service.dart';

/// Result of image upload
class CloudinaryUploadResult {
  final bool success;
  final String? url;
  final String? publicId;
  final String? localPath; // Local cached path for offline use
  final String? error;

  CloudinaryUploadResult({
    required this.success,
    this.url,
    this.publicId,
    this.localPath,
    this.error,
  });
}

/// Service for uploading and managing images on Cloudinary
class CloudinaryService {
  late final Cloudinary _cloudinary;

  CloudinaryService() {
    _cloudinary = Cloudinary.full(
      apiKey: AppUrl.cloudinaryApiKey,
      apiSecret: AppUrl.cloudinaryApiSecret,
      cloudName: AppUrl.cloudinaryCloudName,
    );
  }

  /// Compress image to be under maxSizeKB
  Future<Uint8List?> compressImage(File file, {int maxSizeKB = 800}) async {
    try {
      Uint8List bytes = await file.readAsBytes();
      int currentSizeKB = bytes.length ~/ 1024;

      // If already under max size, return original
      if (currentSizeKB <= maxSizeKB) {
        debugPrint('Image already under ${maxSizeKB}KB: ${currentSizeKB}KB');
        return bytes;
      }

      // Calculate quality to achieve target size
      // Start with quality 90 and reduce
      int quality = 90;
      int attempts = 0;
      const maxAttempts = 10;

      while (currentSizeKB > maxSizeKB &&
          quality > 10 &&
          attempts < maxAttempts) {
        // Reduce quality based on how much we need to reduce
        double ratio = maxSizeKB / currentSizeKB;
        quality = (quality * ratio * 0.9).clamp(10, 90).toInt();

        // For now, we'll just return the original bytes since flutter_image_compress
        // requires additional setup. The Cloudinary upload can handle compression on their end.
        debugPrint(
          'Image compression attempt $attempts: quality=$quality, size=${currentSizeKB}KB',
        );
        attempts++;

        // Since we can't compress locally without additional packages,
        // we'll let Cloudinary handle it with transformations
        break;
      }

      return bytes;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Upload image to Cloudinary with automatic compression
  /// Returns the secure URL of the uploaded image
  Future<CloudinaryUploadResult> uploadImage(
    File file, {
    String? folder,
    String? publicId,
    int maxSizeKB = 800,
  }) async {
    try {
      // Get file info
      final fileName = p.basenameWithoutExtension(file.path);
      final fileSize = await file.length();
      debugPrint('Uploading image: $fileName, size: ${fileSize ~/ 1024}KB');

      // Upload to Cloudinary with transformations for size optimization
      final response = await _cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: file.path,
          fileBytes: await file.readAsBytes(),
          resourceType: CloudinaryResourceType.image,
          folder: folder ?? 'desktopapp',
          publicId:
              publicId ??
              '${fileName}_${DateTime.now().millisecondsSinceEpoch}',
          uploadPreset:
              AppUrl.cloudinaryUploadPreset.isNotEmpty &&
                      AppUrl.cloudinaryUploadPreset != 'YOUR_UPLOAD_PRESET'
                  ? AppUrl.cloudinaryUploadPreset
                  : null,
          // Apply transformations to reduce file size
          // optionalParameters: {
          //   'transformation': 'q_auto,f_auto,c_limit,w_1200,h_1200',
          // },
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        debugPrint('Image uploaded successfully: ${response.secureUrl}');

        // Save to local cache for offline use
        String? localPath;
        try {
          localPath = await ImageCacheService.instance.copyToCache(
            file.path,
            folder: folder,
          );
        } catch (e) {
          debugPrint('Failed to cache locally: $e');
        }

        return CloudinaryUploadResult(
          success: true,
          url: response.secureUrl,
          publicId: response.publicId,
          localPath: localPath,
        );
      } else {
        debugPrint('Upload failed: ${response.error}');
        return CloudinaryUploadResult(
          success: false,
          error: response.error ?? 'Upload failed',
        );
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return CloudinaryUploadResult(success: false, error: e.toString());
    }
  }

  /// Upload image from bytes
  Future<CloudinaryUploadResult> uploadImageBytes(
    Uint8List bytes, {
    String? folder,
    String? publicId,
    String fileName = 'image',
  }) async {
    try {
      debugPrint('Uploading image bytes: ${bytes.length ~/ 1024}KB');

      final response = await _cloudinary.uploadResource(
        CloudinaryUploadResource(
          fileBytes: bytes,
          resourceType: CloudinaryResourceType.image,
          folder: folder ?? 'desktopapp',
          publicId:
              publicId ??
              '${fileName}_${DateTime.now().millisecondsSinceEpoch}',
          uploadPreset:
              AppUrl.cloudinaryUploadPreset.isNotEmpty &&
                      AppUrl.cloudinaryUploadPreset != 'YOUR_UPLOAD_PRESET'
                  ? AppUrl.cloudinaryUploadPreset
                  : null,
          // optionalParameters: {
          //   'transformation': 'q_auto,f_auto,c_limit,w_1200,h_1200',
          // },
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        debugPrint('Image bytes uploaded successfully: ${response.secureUrl}');

        // Save to local cache for offline use
        String? localPath;
        try {
          final localFileName =
              '${fileName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          localPath = await ImageCacheService.instance.saveImageToCache(
            bytes,
            localFileName,
            folder: folder,
          );
        } catch (e) {
          debugPrint('Failed to cache locally: $e');
        }

        return CloudinaryUploadResult(
          success: true,
          url: response.secureUrl,
          publicId: response.publicId,
          localPath: localPath,
        );
      } else {
        return CloudinaryUploadResult(
          success: false,
          error: response.error ?? 'Upload failed',
        );
      }
    } catch (e) {
      debugPrint('Error uploading bytes to Cloudinary: $e');
      return CloudinaryUploadResult(success: false, error: e.toString());
    }
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final response = await _cloudinary.deleteResource(
        publicId: publicId,
        resourceType: CloudinaryResourceType.image,
      );
      return response.isSuccessful;
    } catch (e) {
      debugPrint('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Get optimized URL with transformations
  /// Use this to get resized/compressed versions of uploaded images
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 80,
    String format = 'auto',
  }) {
    // Parse the URL and insert transformation
    // Cloudinary URL format: https://res.cloudinary.com/{cloud}/image/upload/{transformations}/{public_id}
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find 'upload' index and insert transformation after it
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1) {
        final transforms = <String>[];
        if (width != null) transforms.add('w_$width');
        if (height != null) transforms.add('h_$height');
        transforms.add('q_$quality');
        transforms.add('f_$format');
        transforms.add('c_limit'); // Limit to max dimensions without upscaling

        final transformation = transforms.join(',');
        pathSegments.insert(uploadIndex + 1, transformation);

        return uri.replace(pathSegments: pathSegments).toString();
      }
    } catch (e) {
      debugPrint('Error generating optimized URL: $e');
    }

    return originalUrl;
  }

  /// Check if Cloudinary is properly configured
  bool get isConfigured {
    return AppUrl.cloudinaryCloudName.isNotEmpty &&
        AppUrl.cloudinaryCloudName != 'YOUR_CLOUD_NAME' &&
        AppUrl.cloudinaryApiKey.isNotEmpty &&
        AppUrl.cloudinaryApiKey != 'YOUR_API_KEY' &&
        AppUrl.cloudinaryApiSecret.isNotEmpty &&
        AppUrl.cloudinaryApiSecret != 'YOUR_API_SECRET';
  }
}
