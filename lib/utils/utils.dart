import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_sizes.dart';
// Ensure this path matches your project

class Utils {
  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  // static void hideStatusBar() {
  //     SystemChrome.setEnabledSystemUIOverlays([]);
  // }

  // static void showStatusBar() {
  //     SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  // }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static bool isDesktopScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppSizes.desktopScreenSize;
  }

  static bool isTabletScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppSizes.tabletScreenSize &&
        MediaQuery.of(context).size.width < AppSizes.desktopScreenSize;
  }

  static bool isMobileScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < AppSizes.tabletScreenSize;
  }

  // ! ------------------ Field Focus --------------------------------
  static void fieldFocusChange(
    BuildContext context,
    FocusNode current,
    FocusNode nextFocus,
  ) {
    current.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  // ! -------------------- SnackBar --------------------------------
}

final List<Color> colorsList = [
  // ================= BLACK & GREY SHADES =================
  Colors.black,
  const Color(0xFF0D0D0D), // Off Black
  const Color(0xFF1A1A1A), // Darkest Grey
  const Color(0xFF262626), // Charcoal Black
  const Color(0xFF333333), // Jet Black
  const Color(0xFF404040), // Dark Grey
  const Color(0xFF4D4D4D), // Anthracite
  const Color(0xFF595959), // Smokey Grey
  const Color(0xFF666666), // Steel Grey
  const Color(0xFF737373), // Graphite Grey
  const Color(0xFF808080), // Neutral Grey
  const Color(0xFF999999), // Mid Grey
  const Color(0xFFB3B3B3), // Light Graphite
  const Color(0xFFC0C0C0), // Silver Grey
  const Color(0xFFE0E0E0), // Soft Grey
  Colors.white,

  // ================= RED SHADES =================
  Colors.red,
  Colors.redAccent,
  const Color(0xFFFFC0CB), // Light Pink
  const Color(0xFFFF69B4), // Hot Pink
  const Color(0xFF8B0000), // Dark Red
  const Color(0xFFB22222), // Firebrick
  const Color(0xFFDC143C), // Crimson
  // ================= BLUE SHADES =================
  Colors.blue,
  Colors.blueAccent,
  const Color(0xFF1E90FF), // Dodger Blue
  const Color(0xFF4682B4), // Steel Blue
  const Color(0xFF5F9EA0), // Cadet Blue
  const Color(0xFF00008B), // Dark Blue
  const Color(0xFF191970), // Midnight Blue
  // ================= GREEN SHADES =================
  Colors.green,
  Colors.greenAccent,
  const Color(0xFF00FF7F), // Spring Green
  const Color(0xFF2E8B57), // Sea Green
  const Color(0xFF008000), // Dark Green
  const Color(0xFF006400), // Deep Green
  const Color(0xFF9ACD32), // Yellow Green
  // ================= YELLOW & ORANGE SHADES =================
  Colors.yellow,
  Colors.orange,
  Colors.orangeAccent,
  const Color(0xFFFFD700), // Gold
  const Color(0xFFFFA500), // Dark Orange
  const Color(0xFFFF4500), // Orange Red
  const Color(0xFFDAA520), // Golden Rod
  // ================= PURPLE & PINK SHADES =================
  Colors.purple,
  Colors.purpleAccent,
  const Color(0xFF8A2BE2), // Blue Violet
  const Color(0xFF9400D3), // Dark Violet
  const Color(0xFF4B0082), // Indigo
  const Color(0xFF9932CC), // Dark Orchid
  const Color(0xFFDDA0DD), // Plum
  const Color(0xFFFF00FF), // Magenta
  // ================= CYAN & TEAL SHADES =================
  Colors.cyan,
  Colors.teal,
  const Color(0xFF00FFFF), // Aqua
  const Color(0xFF40E0D0), // Turquoise
  const Color(0xFF48D1CC), // Medium Turquoise
  const Color(0xFF008B8B), // Dark Cyan
  const Color(0xFF20B2AA), // Light Sea Green
  // ========== ORANGE SHADES ==========
  Colors.orange, // Default Orange
  Colors.orangeAccent, // Light Orange
  const Color(0xFFFFA500), // Deep Orange
  const Color(0xFFFF8C00), // Darker Orange
  const Color(0xFFFF7F50), // Coral Orange
  const Color(0xFFFF6347), // Tomato Orange
  const Color(0xFFFF4500), // Orange Red
  const Color(0xFFCC5500), // Burnt Orange
  const Color(0xFFB7410E), // Rust Orange
  const Color(0xFF8B4000), // Bronze Orange
  const Color(0xFFD2691E), // Chocolate Orange
  const Color(0xFFCD853F), // Peru (Light Brown Orange)
  const Color(0xFFE9967A), // Sandy Brown
  const Color(0xFFFFE4B5), // Soft Orange (Moccasin)
  // ========== OTHER COLORS ==========
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.cyan,
  Colors.teal,
  Colors.pink,
  Colors.brown,
  Colors.black,
  Colors.grey,
  Colors.white,
];
