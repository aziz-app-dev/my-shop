import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// API key lives in a git-ignored local file so the secret never enters
// version control (GitHub push-protection blocks committing it).
import 'gemini_api_key_secret.dart';

/// One AI suggestion parsed from a product photo.
class ProductAiSuggestion {
  final String? name;
  final String? brand;
  final String? category;
  final String? description;

  /// true only when the photo clearly shows a service being performed.
  final bool isService;

  const ProductAiSuggestion({
    this.name,
    this.brand,
    this.category,
    this.description,
    this.isService = false,
  });

  factory ProductAiSuggestion.fromJson(Map<String, dynamic> json) {
    return ProductAiSuggestion(
      name: (json['name'] as String?)?.trim().nonEmptyOrNull(),
      brand: (json['brand'] as String?)?.trim().nonEmptyOrNull(),
      category: (json['category'] as String?)?.trim().nonEmptyOrNull(),
      description: (json['description'] as String?)?.trim().nonEmptyOrNull(),
      isService: json['isService'] == true,
    );
  }
}

extension _NullIfEmpty on String {
  String? nonEmptyOrNull() => isEmpty ? null : this;
}

/// Product photo analysis with the Gemini API (free tier).
///
/// The user adds a product photo; we ask Gemini to identify the product and
/// return structured details (name / brand / category / description / type)
/// which the Add Product screen uses to auto-fill the still-empty fields.
///
/// Auth uses the `x-goog-api-key` header. Models can retire or hit demand
/// spikes, so a fallback chain is tried top-down.
class GeminiProductVision {
  GeminiProductVision._();

  /// Gemini API key (mounted from the git-ignored
  /// `gemini_api_key_secret.dart` — see that file for the key holder).
  static const String apiKey = geminiApiKey;

  /// Cheap, fast model first; verified working on the free tier.
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
  ];

  /// Analyses the product image at [imagePath]. Returns `null` (never
  /// throws) when anything goes offline/invalid — the form just stays as it
  /// was, so a missing key or network gap can never break the workflow.
  static Future<ProductAiSuggestion?> analyzeProductImage(
    String imagePath, {
    List<String> brands = const [],
    List<String> categories = const [],
  }) async {
    for (final model in _models) {
      try {
        final result = await _callModel(
          model,
          imagePath,
          brands: brands,
          categories: categories,
        );
        if (result != null) return result;
        // No usable answer from this model — try the next one.
      } catch (e) {
        debugPrint('GeminiProductVision($model) error: $e');
      }
    }
    return null;
  }

  static Future<ProductAiSuggestion?> _callModel(
    String model,
    String imagePath, {
    required List<String> brands,
    required List<String> categories,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final brandList = brands.isEmpty ? 'not provided' : brands.join(', ');
    final categoryList =
        categories.isEmpty ? 'not provided' : categories.join(', ');

    final prompt = '''
Identify the product (or service) shown in this photo for a shop POS app.

Available brands in the shop: $brandList
Available categories in the shop: $categoryList

If the brand or category of the product is one of those listed, use it
EXACTLY as written. If it is not in the lists, come up with a short
reasonable one instead.

Reply with ONLY a minified JSON object, no markdown fences, exactly this
shape:
{"name":"short product name","category":"...","brand":"...","description":"one short sentence a shop owner would recognise","isService":false}

Rules:
- description: max 1 sentence.
- isService: true ONLY if the photo clearly shows a service being
  performed (repair, barber, laundry...) rather than an item for sale.
- If a detail is genuinely invisible/unknowable, use "" for it.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': _sniffMimeType(bytes, imagePath),
                'data': base64Encode(bytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.1,
        'maxOutputTokens': 300,
      },
    });

    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
          ),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'x-goog-api-key': apiKey,
          },
          body: utf8.encode(body),
        )
        .timeout(const Duration(seconds: 45));

    debugPrint(
      'GeminiProductVision($model): status ${response.statusCode}, '
      'bytes ${bytes.length}',
    );
    if (response.statusCode != 200) {
      debugPrint('GeminiProductVision($model) body: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = (candidates.first as Map)['content'];
    final parts = (content as Map)['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    final text = ((parts.first as Map)['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return null;

    // The model was told no fences, but strip a possible ```json wrapper
    // just in case.
    var cleaned = text;
    if (cleaned.startsWith('```')) {
      cleaned =
          cleaned
              .replaceFirst(RegExp(r'^```[a-zA-Z]*'), '')
              .replaceFirst(RegExp(r'```$'), '')
              .trim();
    }

    final parsed = jsonDecode(cleaned);
    if (parsed is! Map<String, dynamic>) return null;
    return ProductAiSuggestion.fromJson(parsed);
  }

  /// Cheap magic-number sniff with a filename fallback so camera/shell
  /// picks (any gallery/camera provider) stay correct.
  static String _sniffMimeType(List<int> bytes, String path) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    if (bytes.length >= 3 && bytes[0] == 0x47 && bytes[1] == 0x49) {
      return 'image/gif';
    }
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
