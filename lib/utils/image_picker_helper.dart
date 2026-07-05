import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Global image picker helper to prevent "already_active" errors.
/// The platform-level ImagePicker is a singleton, so we need a global guard.
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();
  static bool _isActive = false;

  /// Pick an image from gallery. Returns null if picker is already active or cancelled.
  static Future<File?> pickImageFromGallery() async {
    if (_isActive) return null;
    _isActive = true;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } finally {
      _isActive = false;
    }
  }

  /// Pick an image from camera. Returns null if picker is already active or cancelled.
  static Future<File?> pickImageFromCamera() async {
    if (_isActive) return null;
    _isActive = true;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      return pickedFile != null ? File(pickedFile.path) : null;
    } finally {
      _isActive = false;
    }
  }

  /// Pick multiple images from gallery. Returns empty list if picker is already active.
  static Future<List<File>> pickMultipleImages() async {
    if (_isActive) return [];
    _isActive = true;
    try {
      final pickedFiles = await _picker.pickMultiImage();
      return pickedFiles.map((f) => File(f.path)).toList();
    } finally {
      _isActive = false;
    }
  }

  /// Check if picker is currently active
  static bool get isActive => _isActive;
}
