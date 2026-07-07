// TEMPLATE — copy this file to `app_url.dart` and fill in your own credentials.
// `app_url.dart` is gitignored so real secrets never get committed.
//
//   cp lib/res/app_url/app_url.example.dart lib/res/app_url/app_url.dart
//
class AppUrl {
  // Base URLs (legacy - can be removed if not used)
  static const String baseUrl = 'https://reqres.in';
  static const String loginApi = '$baseUrl/api/login';
  static const String userListApi =
      'https://jsonplaceholder.typicode.com/users';
  static const String postListApi =
      'https://jsonplaceholder.typicode.com/posts';

  // NOTE: Cloud auth/data/backup use Firebase — configure via `flutterfire
  // configure` (generates firebase_options.dart + google-services.json).

  // ============ CLOUDINARY CONFIGURATION ============
  // Get these from: Cloudinary Dashboard > Settings > Access Keys
  // Create an unsigned upload preset in: Settings > Upload > Upload presets
  static const String cloudinaryCloudName =
      'YOUR_CLOUD_NAME'; // Replace with your cloud name
  static const String cloudinaryApiKey =
      'YOUR_API_KEY'; // Replace with your API key
  static const String cloudinaryApiSecret =
      'YOUR_API_SECRET'; // Replace with your API secret
  static const String cloudinaryUploadPreset =
      'YOUR_UPLOAD_PRESET'; // Create unsigned preset in Cloudinary

  // Cloudinary upload URL
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // ============ IMAGE SETTINGS ============
  // Maximum image size in bytes (800KB)
  static const int maxImageSizeBytes = 800 * 1024; // 800KB
  static const int maxImageSizeKB = 800;
}
