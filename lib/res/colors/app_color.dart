import 'package:flutter/material.dart';

class AppColors {
  static const List<Color> chartColors = [
    AppColors.primary,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
  ];
  static const Color primary = Color(0xFFff6701); // Purple
  static const Color primaryLight1 = Color(0xFFff8530); // Light Purple
  static const Color primaryLight2 = Color(0xFFffa360); // Light Purple
  static const Color primaryLight3 = Color(0xFFffc08f); // Light Purple
  static const Color primaryLight4 = Color(0xFFffdebe); // Light Purple

  //! Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color scaffoldBackground = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF0F0F0);

  // ! text fields colors
  static const Color textFieldsColor = Color(0xFFff6701);
  // ! icon colors
  static const Color iconColor = Color(0xFFff6701);
  // Text Colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFFFFFFF);

  // Border and Dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors (Greys)
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  static const Color dBodyColor = Color(0xFF212121);
  static final Color? dScafoldColor = Colors.grey[850];
  static final Color? dAppBarColor = Colors.grey[900];
  static final Color dAppBarTitleColor = Colors.white;
  static final Color dAppBarIconColor = Colors.white;
  static final Color? dCardColor = Colors.grey[900];
  static final Color dDividerColor = Colors.white;
  static final Color? dBottomNavBarColor = Colors.grey[900];

  static final Color lTFieldColor = Colors.white;
  static final Color? dTFieldColor = Colors.grey[900];
  static final Color lTFieldColorBorder = Colors.white;
  static final Color? dTFieldColorBorder = Colors.grey[900];
  static final Color? lTFieldHintColor = Colors.grey[900];
  static final Color dTFieldHintColor = Colors.white;

  static const Color lBodyColor = Color(0xFFF5F5F5);
  static final Color lScafoldColor = Color(0xFFF5F5F5);
  static final Color lAppBarColor = Colors.white;
  static final Color lAppBarTitleColor = Colors.black;
  static final Color lAppBarIconColor = Colors.black;
  static final Color lCardColor = Colors.white;

  static final Color? lIconColor = Colors.grey[700];
  static final Color dIconColor = Colors.white;

  // Transparent Overlays
  static const Color overlayLight = Color(0x80FFFFFF); // 50% white
  static const Color overlayDark = Color(0x80000000); // 50% black
}



// (Theme.of(context).brightness ==
//                                           Brightness.dark
//                                       ? AppColors.grey300
//                                       : AppColors.grey600),