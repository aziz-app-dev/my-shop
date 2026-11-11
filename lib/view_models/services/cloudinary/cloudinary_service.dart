import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a Cloudinary upload. [success] is always non-null so callers
/// can branch safely; [url] is the CDN URL on success, [error] explains the
/// failure otherwise.
class CloudinaryUploadResult {
  final bool success;
  final String? url;
  final String? error;

  const CloudinaryUploadResult({required this.success, this.url, this.error});
}

/// Cloudinary cloud image hosting (unsigned uploads).
///
/// Credentials come from Settings → API Keys (cloud name + unsigned upload
/// preset). They are pushed into this service by [SettingsNotifier] — the
/// settings box is the single source of truth, nothing is hard-coded.
///
/// Unsigned uploads need only cloud name + preset, so no API secret lives
/// in the app.
class CloudinaryService {
  CloudinaryService._internal();

  /// Shared instance — call sites do `CloudinaryService()`-style access via
  /// [instance]; keep one object so configuration is global.
  static final CloudinaryService instance = CloudinaryService._internal();

  /// Convenience constructor so call sites can write `CloudinaryService()`.
  factory CloudinaryService() => instance;

  /// Pushed from the settings box (loaded at startup and on every change).
  static String _cloudName = '';
  static String _uploadPreset = '';

  /// Called by SettingsNotifier whenever settings load or the keys change.
  static void configure({
    required String cloudName,
    required String uploadPreset,
  }) {
    _cloudName = cloudName.trim();
    _uploadPreset = uploadPreset.trim();
    debugPrint(
      'CloudinaryService configured: '
      'cloud=$_cloudName preset=${_uploadPreset.isEmpty ? '(none)' : 'set'}',
    );
  }

  /// True when both credentials are present (Settings → API Keys).
  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  /// Uploads [file] to Cloudinary as an image. Never throws — a failed or
  /// unconfigured upload returns [CloudinaryUploadResult.success] = false.
  Future<CloudinaryUploadResult> uploadImage(
    File file, {
    String? folder,
  }) async {
    if (!isConfigured) {
      return const CloudinaryUploadResult(
        success: false,
        error:
            'Cloudinary is not configured — add the cloud name and upload '
            'preset in Settings → API Keys.',
      );
    }
    try {
      if (!await file.exists()) {
        return const CloudinaryUploadResult(
          success: false,
          error: 'Image file not found.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const CloudinaryUploadResult(
          success: false,
          error: 'Image file is empty.',
        );
      }

      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(
                'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
              ),
            )
            ..fields['upload_preset'] = _uploadPreset
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: file.uri.pathSegments.last,
              ),
            );
      if (folder != null && folder.trim().isNotEmpty) {
        request.fields['folder'] = folder.trim();
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamed);
      debugPrint('CloudinaryService: status ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('CloudinaryService body: ${response.body}');
        String message = 'Upload failed (HTTP ${response.statusCode}).';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final apiError = data['error'];
          if (apiError is Map && apiError['message'] is String) {
            message = apiError['message'] as String;
          }
        } catch (_) {}
        return CloudinaryUploadResult(success: false, error: message);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        return const CloudinaryUploadResult(
          success: false,
          error: 'Cloudinary did not return a URL.',
        );
      }
      return CloudinaryUploadResult(success: true, url: url);
    } catch (e) {
      debugPrint('CloudinaryService.uploadImage error: $e');
      return CloudinaryUploadResult(success: false, error: 'Upload failed: $e');
    }
  }

  /// 1×1 transparent PNG used for the live "Test Upload" in Settings.
  static const String _testPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M'
      '9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  /// Live check for the Settings screen: uploads a tiny 1×1 PNG using the
  /// ENTERED (not yet saved) cloud name + upload preset. `true` means
  /// Cloudinary accepted both values. Returns `false` (never throws) on
  /// anything else.
  static Future<bool> testCredentials({
    required String cloudName,
    required String uploadPreset,
  }) async {
    if (cloudName.trim().isEmpty || uploadPreset.trim().isEmpty) return false;
    try {
      final tempDir = await Directory.systemTemp.createTemp('cloudinary_test');
      final file = File('${tempDir.path}/settings-test.png');
      await file.writeAsBytes(base64Decode(_testPngBase64));
      try {
        final request =
            http.MultipartRequest(
                'POST',
                Uri.parse(
                  'https://api.cloudinary.com/v1_1/'
                  '${cloudName.trim()}/image/upload',
                ),
              )
              ..fields['upload_preset'] = uploadPreset.trim()
              ..files.add(
                http.MultipartFile.fromBytes(
                  'file',
                  base64Decode(_testPngBase64),
                  filename: 'settings-test.png',
                ),
              );

        final streamed = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final response = await http.Response.fromStream(streamed);
        debugPrint('CloudinaryService.testCredentials: ${response.statusCode}');
        return response.statusCode == 200;
      } finally {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('CloudinaryService.testCredentials error: $e');
      return false;
    }
  }
}
