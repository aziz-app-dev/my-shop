import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// Service for caching images locally with network fallback
class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._();

  ImageCacheService._();

  String? _cacheDirectory;

  /// Initialize the cache directory
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _cacheDirectory = path.join(directory.path, 'image_cache');
    final cacheDir = Directory(_cacheDirectory!);
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
  }

  /// Get the cache directory path
  Future<String> get cacheDirectory async {
    if (_cacheDirectory == null) {
      await init();
    }
    return _cacheDirectory!;
  }

  /// Generate a local file path for a URL
  Future<String> getLocalPathForUrl(String url, {String? folder}) async {
    final cacheDir = await cacheDirectory;
    final fileName = _getFileNameFromUrl(url);
    if (folder != null) {
      final folderPath = path.join(cacheDir, folder);
      final folderDir = Directory(folderPath);
      if (!folderDir.existsSync()) {
        folderDir.createSync(recursive: true);
      }
      return path.join(folderPath, fileName);
    }
    return path.join(cacheDir, fileName);
  }

  /// Extract filename from URL or generate one
  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        // Get the last segment which is usually the filename
        String fileName = pathSegments.last;
        // If it doesn't have an extension, add .jpg
        if (!fileName.contains('.')) {
          fileName = '$fileName.jpg';
        }
        // Remove any query parameters from filename
        if (fileName.contains('?')) {
          fileName = fileName.split('?').first;
        }
        return fileName;
      }
    } catch (e) {
      debugPrint('Error parsing URL: $e');
    }
    // Fallback: generate filename from URL hash
    return '${url.hashCode.abs()}.jpg';
  }

  /// Check if image is cached locally
  Future<bool> isImageCached(String url) async {
    final localPath = await getLocalPathForUrl(url);
    return File(localPath).existsSync();
  }

  /// Get local path if cached, otherwise return null
  Future<String?> getCachedImagePath(String url) async {
    final localPath = await getLocalPathForUrl(url);
    final file = File(localPath);
    if (file.existsSync()) {
      return localPath;
    }
    return null;
  }

  /// Download and cache image from URL
  /// Returns local file path on success, null on failure
  Future<String?> downloadAndCacheImage(
    String url, {
    String? folder,
  }) async {
    try {
      final localPath = await getLocalPathForUrl(url, folder: folder);
      final file = File(localPath);

      // If already cached, return the path
      if (file.existsSync()) {
        debugPrint('Image already cached: $localPath');
        return localPath;
      }

      // Download the image
      debugPrint('Downloading image: $url');
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Image cached: $localPath');
        return localPath;
      } else {
        debugPrint('Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }

  /// Save image bytes to local cache
  Future<String?> saveImageToCache(
    Uint8List bytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      final cacheDir = await cacheDirectory;
      String filePath;

      if (folder != null) {
        final folderPath = path.join(cacheDir, folder);
        final folderDir = Directory(folderPath);
        if (!folderDir.existsSync()) {
          folderDir.createSync(recursive: true);
        }
        filePath = path.join(folderPath, fileName);
      } else {
        filePath = path.join(cacheDir, fileName);
      }

      final file = File(filePath);
      await file.writeAsBytes(bytes);
      debugPrint('Image saved to cache: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving image to cache: $e');
      return null;
    }
  }

  /// Copy local file to cache directory
  Future<String?> copyToCache(String localPath, {String? folder}) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        debugPrint('Source file does not exist: $localPath');
        return null;
      }

      final cacheDir = await cacheDirectory;
      final fileName = path.basename(localPath);
      String destPath;

      if (folder != null) {
        final folderPath = path.join(cacheDir, folder);
        final folderDir = Directory(folderPath);
        if (!folderDir.existsSync()) {
          folderDir.createSync(recursive: true);
        }
        destPath = path.join(folderPath, fileName);
      } else {
        destPath = path.join(cacheDir, fileName);
      }

      // Copy file
      await file.copy(destPath);
      debugPrint('Image copied to cache: $destPath');
      return destPath;
    } catch (e) {
      debugPrint('Error copying image to cache: $e');
      return null;
    }
  }

  /// Delete cached image
  Future<bool> deleteCachedImage(String url) async {
    try {
      final localPath = await getLocalPathForUrl(url);
      final file = File(localPath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting cached image: $e');
      return false;
    }
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    try {
      final cacheDir = await cacheDirectory;
      final dir = Directory(cacheDir);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      debugPrint('Image cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await cacheDirectory;
      final dir = Directory(cacheDir);
      if (!dir.existsSync()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  /// Get cache size formatted as string
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
