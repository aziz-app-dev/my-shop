import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../res/colors/app_color.dart';
import '../../../utils/app_sizes.dart';

class AppTheme {
  static ThemeData lightTheme(
    double appBarElevation,
    double cardElevation, {
    Color primaryColor = const Color(0xFFff6701),
  }) {
    final base = ThemeData.dark();

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lScafoldColor,
      iconTheme: IconThemeData(color: AppColors.lIconColor),
      // floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white,
      ),
      //  drop down
      popupMenuTheme: PopupMenuThemeData(color: AppColors.grey100),
      // Text
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lAppBarColor,
        surfaceTintColor: AppColors.lAppBarColor,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: appBarElevation,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.spMin,
          fontWeight: FontWeight.w600,
          color: AppColors.lAppBarTitleColor,
        ),
        iconTheme: IconThemeData(color: AppColors.lAppBarIconColor),
      ),
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.dDividerColor,
        thickness: 1,
        space: 1,
      ),
      // Card
      cardTheme: CardThemeData(
        color: AppColors.lCardColor,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        ),
      ),
      // CheckboxListTile
      listTileTheme: ListTileThemeData(textColor: Colors.black),
      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey[300],
        thumbColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        overlayColor: primaryColor.withValues(alpha: 0.2),
        valueIndicatorColor: primaryColor,
        trackHeight: 4,
      ),
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey[400],
        ),
        overlayColor: WidgetStateProperty.all(
          primaryColor.withValues(alpha: 0.2),
        ),
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey[700],
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor.withValues(alpha: 0.5)
                  : Colors.grey[400],
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.grey[600],
        ),

        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey[700],
        ),

        thumbIcon: WidgetStateProperty.all(
          Icon(Icons.circle, color: Colors.grey[100]),
        ),
      ),
      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: primaryColor,
        collapsedIconColor: AppColors.lAppBarIconColor,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        textColor: AppColors.lAppBarTitleColor,
        collapsedTextColor: Colors.black87,
        backgroundColor: AppColors.lCardColor,
        collapsedBackgroundColor: AppColors.lCardColor,
        expansionAnimationStyle: AnimationStyle(
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 300),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lBodyColor,
        surfaceTintColor: Colors.black,
        iconColor: Colors.black,
        titleTextStyle: TextStyle(color: Colors.black),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(
              AppSizes.borderRadiusMd,
            ), // Rounded corners with radius 6
          ),
        ),
      ),

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData darkTheme(
    double appBarElevation,
    double cardElevation, {
    Color primaryColor = const Color(0xFFff6701),
  }) {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dScafoldColor,
      iconTheme: IconThemeData(color: AppColors.dIconColor),

      // floating Action
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
      ),
      //  drop down
      popupMenuTheme: PopupMenuThemeData(color: AppColors.dBodyColor),
      // Text
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dAppBarColor,
        surfaceTintColor: AppColors.dAppBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: appBarElevation,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18.spMin,
          fontWeight: FontWeight.w600,
          color: AppColors.dAppBarTitleColor,
        ),
        iconTheme: IconThemeData(color: AppColors.dAppBarIconColor),
      ),
      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.dDividerColor,
        thickness: 1,
        space: 1,
      ),
      // Card
      cardTheme: CardThemeData(
        color: AppColors.dCardColor,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        elevation: cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        ),
      ),
      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Colors.blue[200],
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
      ),
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: Colors.grey[700],
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.3),
        valueIndicatorColor: primaryColor,
        trackHeight: 4,
      ),
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.transparent,
        ),
        side: BorderSide(color: Colors.white),
        checkColor: WidgetStateProperty.all(Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.black),
        ),
      ),
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey[600],
        ),
        overlayColor: WidgetStateProperty.all(
          primaryColor.withValues(alpha: 0.3),
        ),
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : AppColors.dBottomNavBarColor,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor.withValues(alpha: 0.5)
                  : Colors.grey[800],
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor.withValues(alpha: 0.3)
                  : Colors.grey[700],
        ),

        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey[800],
        ),

        thumbIcon: WidgetStateProperty.all(
          Icon(Icons.circle, color: Colors.transparent),
        ),
      ),
      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: primaryColor,
        collapsedIconColor: AppColors.textLight,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        textColor: AppColors.dAppBarTitleColor,
        collapsedTextColor: AppColors.dAppBarTitleColor,
        backgroundColor: AppColors.dCardColor,
        collapsedBackgroundColor: AppColors.dCardColor,
        expansionAnimationStyle: AnimationStyle(
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 300),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dBodyColor,
        surfaceTintColor: Colors.white,
        iconColor: Colors.white,
        titleTextStyle: TextStyle(color: Colors.white),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(
              AppSizes.borderRadiusMd,
            ), // Rounded corners with radius 6
          ),
        ),
      ),

      // CheckboxListTile
      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      ),
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
