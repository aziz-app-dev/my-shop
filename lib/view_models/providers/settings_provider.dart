import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database/database_services.dart';
import 'package:riverpod/legacy.dart';

// Print format options
enum PrintFormat {
  thermal, // Thermal receipt printer
  pdf, // PDF bill (A4)
}

// Bill PDF design options
enum BillDesign {
  classic, // Original simple design
  minimal, // Ultra minimal, text-focused design
  modern, // Full A4 invoice with social media, terms & conditions
  invoice, // Trader-style invoice with colored sidebar
}

// Thermal receipt design options
enum ThermalDesign {
  classic, // Full featured with shop logo, QR code, detailed layout
  minimal, // Simple text-based receipt
}

// Icon style options
enum IconStyle {
  defaultStyle, // Flutter default icons (Material icons)
  windows11, // Windows 11 style PNG icons
  // Add more styles here in the future (e.g., ios, fluent, etc.)
}

// Predefined app color options
class AppColorOption {
  final String name;
  final Color color;

  const AppColorOption(this.name, this.color);

  static const List<AppColorOption> colors = [
    AppColorOption('Orange', Color(0xFFff6701)),
    AppColorOption('Blue', Color(0xFF2196F3)),
    AppColorOption('Purple', Color(0xFF9C27B0)),
    AppColorOption('Green', Color(0xFF4CAF50)),
    AppColorOption('Red', Color(0xFFF44336)),
    AppColorOption('Teal', Color(0xFF009688)),
    AppColorOption('Indigo', Color(0xFF3F51B5)),
    AppColorOption('Pink', Color(0xFFE91E63)),
    AppColorOption('Amber', Color(0xFFFFC107)),
    AppColorOption('Cyan', Color(0xFF00BCD4)),
  ];

  static Color getColorByValue(int value) {
    return Color(value);
  }
}

class SettingsState {
  final bool isPrintEnabled; // Master switch for printing
  final PrintFormat printFormat; // Thermal or PDF
  final BillDesign billDesign; // Selected bill PDF design
  final ThermalDesign thermalDesign; // Selected thermal receipt design
  final bool isPDFSave;
  final bool isPaid;
  // Paid stamp settings
  final bool showPaidStamp;
  final String paidStampText;
  final String paidStampSignature;
  final bool showDateOnStamp;
  // Background watermark settings (uses paid stamp image from assets)
  final bool showBackgroundWatermark;
  final double watermarkOpacity;
  // Bank selection for bills (index of selected bank, -1 for none)
  final int selectedBankIndex;
  final bool showBankDetailsOnBill;
  final bool isAutoPrintOnSale; // Auto-print bills after sale completion
  final String directoryPath;
  final bool isShowTagLine;
  final bool isTagLineInsteadOfCEOName;
  final bool isShowUserCard;
  final double cardElevation;
  final double appBarElevation;
  final double productCardElevation;
  final bool isAppLockEnabled;
  final ThemeMode themeMode;
  final bool useMultiCart; // Multi-cart option
  final IconStyle iconStyle; // Icon style preference
  final int primaryColorValue; // Primary color as int value

  // Optional module toggles (show/hide whole features)
  final bool showShoppingListModule;
  final bool showRepairsModule;

  // Getter for primary color
  Color get primaryColor => Color(primaryColorValue);

  // Getters for primary color shades (lighter variations)
  Color get primaryLight1 => _lightenColor(primaryColor, 0.15);
  Color get primaryLight2 => _lightenColor(primaryColor, 0.30);
  Color get primaryLight3 => _lightenColor(primaryColor, 0.45);
  Color get primaryLight4 => _lightenColor(primaryColor, 0.60);

  // Getters for primary color dark shades
  Color get primaryDark1 => _darkenColor(primaryColor, 0.15);
  Color get primaryDark2 => _darkenColor(primaryColor, 0.30);

  // Helper method to lighten a color
  static Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Helper method to darken a color
  static Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Home Page Section Settings
  final bool showBannerSection;
  final List<String> bannerImagePaths;
  final bool bannerAutoScroll;
  final int bannerScrollDuration; // in seconds
  final bool showBrandsSection;
  final bool showCategoriesSection;
  final bool showTopSellingSection;
  final bool showLatestItemsSection;
  final bool showLatestServicesSection;
  final bool showLowStockSection;
  final int productsPerSection; // Default for all
  final int topSellingProductsCount;
  final int latestItemsCount;
  final int latestServicesCount;
  final int lowStockItemsCount;
  final List<String> sectionOrder;

  SettingsState({
    this.isPrintEnabled = false,
    this.printFormat = PrintFormat.pdf, // Default to PDF
    this.billDesign = BillDesign.classic, // Default to classic design
    this.thermalDesign = ThermalDesign.classic, // Default to classic thermal design
    this.isPDFSave = false,
    this.isPaid = false,
    this.showPaidStamp = false,
    this.paidStampText = 'PAID',
    this.paidStampSignature = '',
    this.showDateOnStamp = true,
    this.showBackgroundWatermark = false,
    this.watermarkOpacity = 0.15,
    this.selectedBankIndex = 0, // First bank by default
    this.showBankDetailsOnBill = true, // Show bank details by default
    this.isAutoPrintOnSale = false, // Auto-print disabled by default
    this.directoryPath = '',
    this.isShowTagLine = true,
    this.isTagLineInsteadOfCEOName = false,
    this.isShowUserCard = true,
    this.cardElevation = 4.0,
    this.appBarElevation = 4.0,
    this.productCardElevation = 4.0,
    this.isAppLockEnabled = false,
    this.themeMode = ThemeMode.light,
    this.useMultiCart = false, // Default to single cart
    this.iconStyle = IconStyle.defaultStyle, // Default to Material icons
    this.primaryColorValue = 0xFFff6701, // Default orange color
    this.showShoppingListModule = true,
    this.showRepairsModule = true,
    this.showBannerSection = true,
    this.bannerImagePaths = const [],
    this.bannerAutoScroll = true,
    this.bannerScrollDuration = 5, // 5 seconds default
    this.showBrandsSection = true,
    this.showCategoriesSection = true,
    this.showTopSellingSection = true,
    this.showLatestItemsSection = true,
    this.showLatestServicesSection = true,
    this.showLowStockSection = true,
    this.productsPerSection = 6,
    this.topSellingProductsCount = 6,
    this.latestItemsCount = 6,
    this.latestServicesCount = 6,
    this.lowStockItemsCount = 6,
    this.sectionOrder = const [
      'banner',
      'brands',
      'categories',
      'topSelling',
      'latestItems',
      'latestServices',
      'lowStock',
    ],
  });

  SettingsState copyWith({
    bool? isPrintEnabled,
    PrintFormat? printFormat,
    BillDesign? billDesign,
    ThermalDesign? thermalDesign,
    bool? isPDFSave,
    bool? isPaid,
    bool? showPaidStamp,
    String? paidStampText,
    String? paidStampSignature,
    bool? showDateOnStamp,
    bool? showBackgroundWatermark,
    double? watermarkOpacity,
    int? selectedBankIndex,
    bool? showBankDetailsOnBill,
    bool? isAutoPrintOnSale,
    String? directoryPath,
    bool? isShowTagLine,
    bool? isTagLineInsteadOfCEOName,
    bool? isShowUserCard,
    double? cardElevation,
    double? appBarElevation,
    double? productCardElevation,
    bool? isAppLockEnabled,
    ThemeMode? themeMode,
    bool? useMultiCart,
    IconStyle? iconStyle,
    int? primaryColorValue,
    bool? showShoppingListModule,
    bool? showRepairsModule,
    bool? showBannerSection,
    List<String>? bannerImagePaths,
    bool? bannerAutoScroll,
    int? bannerScrollDuration,
    bool? showBrandsSection,
    bool? showCategoriesSection,
    bool? showTopSellingSection,
    bool? showLatestItemsSection,
    bool? showLatestServicesSection,
    bool? showLowStockSection,
    int? productsPerSection,
    int? topSellingProductsCount,
    int? latestItemsCount,
    int? latestServicesCount,
    int? lowStockItemsCount,
    List<String>? sectionOrder,
  }) {
    return SettingsState(
      isPrintEnabled: isPrintEnabled ?? this.isPrintEnabled,
      printFormat: printFormat ?? this.printFormat,
      billDesign: billDesign ?? this.billDesign,
      thermalDesign: thermalDesign ?? this.thermalDesign,
      isPDFSave: isPDFSave ?? this.isPDFSave,
      isPaid: isPaid ?? this.isPaid,
      showPaidStamp: showPaidStamp ?? this.showPaidStamp,
      paidStampText: paidStampText ?? this.paidStampText,
      paidStampSignature: paidStampSignature ?? this.paidStampSignature,
      showDateOnStamp: showDateOnStamp ?? this.showDateOnStamp,
      showBackgroundWatermark: showBackgroundWatermark ?? this.showBackgroundWatermark,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      selectedBankIndex: selectedBankIndex ?? this.selectedBankIndex,
      showBankDetailsOnBill: showBankDetailsOnBill ?? this.showBankDetailsOnBill,
      isAutoPrintOnSale: isAutoPrintOnSale ?? this.isAutoPrintOnSale,
      directoryPath: directoryPath ?? this.directoryPath,
      isShowTagLine: isShowTagLine ?? this.isShowTagLine,
      isTagLineInsteadOfCEOName:
          isTagLineInsteadOfCEOName ?? this.isTagLineInsteadOfCEOName,
      isShowUserCard: isShowUserCard ?? this.isShowUserCard,
      cardElevation: cardElevation ?? this.cardElevation,
      appBarElevation: appBarElevation ?? this.appBarElevation,
      productCardElevation: productCardElevation ?? this.productCardElevation,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      themeMode: themeMode ?? this.themeMode,
      useMultiCart: useMultiCart ?? this.useMultiCart,
      iconStyle: iconStyle ?? this.iconStyle,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      showShoppingListModule:
          showShoppingListModule ?? this.showShoppingListModule,
      showRepairsModule: showRepairsModule ?? this.showRepairsModule,
      showBannerSection: showBannerSection ?? this.showBannerSection,
      bannerImagePaths: bannerImagePaths ?? this.bannerImagePaths,
      bannerAutoScroll: bannerAutoScroll ?? this.bannerAutoScroll,
      bannerScrollDuration: bannerScrollDuration ?? this.bannerScrollDuration,
      showBrandsSection: showBrandsSection ?? this.showBrandsSection,
      showCategoriesSection:
          showCategoriesSection ?? this.showCategoriesSection,
      showTopSellingSection:
          showTopSellingSection ?? this.showTopSellingSection,
      showLatestItemsSection:
          showLatestItemsSection ?? this.showLatestItemsSection,
      showLatestServicesSection:
          showLatestServicesSection ?? this.showLatestServicesSection,
      showLowStockSection: showLowStockSection ?? this.showLowStockSection,
      productsPerSection: productsPerSection ?? this.productsPerSection,
      topSellingProductsCount:
          topSellingProductsCount ?? this.topSellingProductsCount,
      latestItemsCount: latestItemsCount ?? this.latestItemsCount,
      latestServicesCount: latestServicesCount ?? this.latestServicesCount,
      lowStockItemsCount: lowStockItemsCount ?? this.lowStockItemsCount,
      sectionOrder: sectionOrder ?? this.sectionOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isPrintEnabled': isPrintEnabled,
      'printFormat': printFormat.name, // Save enum as string
      'billDesign': billDesign.name, // Save enum as string
      'thermalDesign': thermalDesign.name, // Save enum as string
      'isPDFSave': isPDFSave,
      'isPaid': isPaid,
      'showPaidStamp': showPaidStamp,
      'paidStampText': paidStampText,
      'paidStampSignature': paidStampSignature,
      'showDateOnStamp': showDateOnStamp,
      'showBackgroundWatermark': showBackgroundWatermark,
      'watermarkOpacity': watermarkOpacity,
      'selectedBankIndex': selectedBankIndex,
      'showBankDetailsOnBill': showBankDetailsOnBill,
      'isAutoPrintOnSale': isAutoPrintOnSale,
      'directoryPath': directoryPath,
      'isShowTagLine': isShowTagLine,
      'isTagLineInsteadOfCEOName': isTagLineInsteadOfCEOName,
      'isShowUserCard': isShowUserCard,
      'cardElevation': cardElevation,
      'appBarElevation': appBarElevation,
      'productCardElevation': productCardElevation,
      'isAppLockEnabled': isAppLockEnabled,
      'themeMode': themeMode.toString(),
      'useMultiCart': useMultiCart,
      'iconStyle': iconStyle.name,
      'primaryColorValue': primaryColorValue,
      'showShoppingListModule': showShoppingListModule,
      'showRepairsModule': showRepairsModule,
      'showBannerSection': showBannerSection,
      'bannerImagePaths': bannerImagePaths,
      'bannerAutoScroll': bannerAutoScroll,
      'bannerScrollDuration': bannerScrollDuration,
      'showBrandsSection': showBrandsSection,
      'showCategoriesSection': showCategoriesSection,
      'showTopSellingSection': showTopSellingSection,
      'showLatestItemsSection': showLatestItemsSection,
      'showLatestServicesSection': showLatestServicesSection,
      'showLowStockSection': showLowStockSection,
      'productsPerSection': productsPerSection,
      'topSellingProductsCount': topSellingProductsCount,
      'latestItemsCount': latestItemsCount,
      'latestServicesCount': latestServicesCount,
      'lowStockItemsCount': lowStockItemsCount,
      'sectionOrder': sectionOrder,
    };
  }

  factory SettingsState.fromMap(Map<String, dynamic> map) {
    // Migrate old sectionOrder to include banner if missing
    List<String> sectionOrder;
    if (map['sectionOrder'] != null) {
      final List<String> savedOrder = List<String>.from(map['sectionOrder']);
      // Check if banner is missing and add it at the beginning
      if (!savedOrder.contains('banner')) {
        sectionOrder = ['banner', ...savedOrder];
      } else {
        sectionOrder = savedOrder;
      }
    } else {
      sectionOrder = const [
        'banner',
        'brands',
        'categories',
        'topSelling',
        'latestItems',
        'latestServices',
        'lowStock',
      ];
    }

    return SettingsState(
      isPrintEnabled:
          map['isPrintEnabled'] ??
          map['isThermalPrint'] ??
          false, // Migration support
      printFormat:
          map['printFormat'] != null
              ? PrintFormat.values.firstWhere(
                (e) => e.name == map['printFormat'],
                orElse: () => PrintFormat.pdf,
              )
              : PrintFormat.pdf,
      billDesign:
          map['billDesign'] != null
              ? BillDesign.values.firstWhere(
                (e) => e.name == map['billDesign'],
                orElse: () => BillDesign.classic,
              )
              : BillDesign.classic,
      thermalDesign:
          map['thermalDesign'] != null
              ? ThermalDesign.values.firstWhere(
                (e) => e.name == map['thermalDesign'],
                orElse: () => ThermalDesign.classic,
              )
              : ThermalDesign.classic,
      isPDFSave: map['isPDFSave'] ?? false,
      isPaid: map['isPaid'] ?? false,
      showPaidStamp: map['showPaidStamp'] ?? false,
      paidStampText: map['paidStampText'] ?? 'PAID',
      paidStampSignature: map['paidStampSignature'] ?? '',
      showDateOnStamp: map['showDateOnStamp'] ?? true,
      showBackgroundWatermark: map['showBackgroundWatermark'] ?? false,
      watermarkOpacity: (map['watermarkOpacity'] as num?)?.toDouble() ?? 0.15,
      selectedBankIndex: map['selectedBankIndex'] ?? 0,
      showBankDetailsOnBill: map['showBankDetailsOnBill'] ?? true,
      isAutoPrintOnSale: map['isAutoPrintOnSale'] ?? false,
      directoryPath: map['directoryPath'] ?? '',
      isShowTagLine: map['isShowTagLine'] ?? true,
      isTagLineInsteadOfCEOName: map['isTagLineInsteadOfCEOName'] ?? false,
      isShowUserCard: map['isShowUserCard'] ?? true,
      cardElevation: (map['cardElevation'] as num?)?.toDouble() ?? 4.0,
      appBarElevation: (map['appBarElevation'] as num?)?.toDouble() ?? 4.0,
      productCardElevation:
          (map['productCardElevation'] as num?)?.toDouble() ?? 4.0,
      isAppLockEnabled: map['isAppLockEnabled'] ?? false,
      themeMode:
          map['themeMode'] == 'ThemeMode.dark'
              ? ThemeMode.dark
              : map['themeMode'] == 'ThemeMode.system'
              ? ThemeMode.system
              : ThemeMode.light,
      useMultiCart: map['useMultiCart'] ?? false,
      iconStyle:
          map['iconStyle'] != null
              ? IconStyle.values.firstWhere(
                (e) => e.name == map['iconStyle'],
                orElse: () => IconStyle.defaultStyle,
              )
              : IconStyle.defaultStyle,
      primaryColorValue: map['primaryColorValue'] ?? 0xFFff6701,
      showShoppingListModule: map['showShoppingListModule'] ?? true,
      showRepairsModule: map['showRepairsModule'] ?? true,
      showBannerSection: map['showBannerSection'] ?? true,
      bannerImagePaths:
          map['bannerImagePaths'] != null
              ? List<String>.from(map['bannerImagePaths'])
              : const [],
      bannerAutoScroll: map['bannerAutoScroll'] ?? true,
      bannerScrollDuration: map['bannerScrollDuration'] ?? 5,
      showBrandsSection: map['showBrandsSection'] ?? true,
      showCategoriesSection: map['showCategoriesSection'] ?? true,
      showTopSellingSection: map['showTopSellingSection'] ?? true,
      showLatestItemsSection: map['showLatestItemsSection'] ?? true,
      showLatestServicesSection: map['showLatestServicesSection'] ?? true,
      showLowStockSection: map['showLowStockSection'] ?? true,
      productsPerSection: map['productsPerSection'] ?? 6,
      topSellingProductsCount: map['topSellingProductsCount'] ?? 6,
      latestItemsCount: map['latestItemsCount'] ?? 6,
      latestServicesCount: map['latestServicesCount'] ?? 6,
      lowStockItemsCount: map['lowStockItemsCount'] ?? 6,
      sectionOrder: sectionOrder,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final HiveService _hiveService;

  SettingsNotifier(this._hiveService) : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsBox = await _hiveService.getSettingsBox();
    final directoryPath = await _hiveService.directoryPath;
    final settingsMap =
        settingsBox.get('settings', defaultValue: {}) as Map<dynamic, dynamic>;

    // Load settings with migration
    state = SettingsState.fromMap({
      ...settingsMap,
      'directoryPath': directoryPath,
    });

    // Save migrated settings to persist banner in sectionOrder
    final savedOrder = settingsMap['sectionOrder'] as List?;
    if (savedOrder != null && !savedOrder.contains('banner')) {
      // Banner was added during migration, save it
      await _saveSettings();
    }
  }

  Future<void> _saveSettings() async {
    final settingsBox = await _hiveService.getSettingsBox();
    await settingsBox.put('settings', state.toMap());
  }

  void setPrintEnabled(bool value) {
    state = state.copyWith(isPrintEnabled: value);
    _saveSettings();
  }

  void setPrintFormat(PrintFormat format) {
    state = state.copyWith(printFormat: format);
    _saveSettings();
  }

  void setBillDesign(BillDesign design) {
    state = state.copyWith(billDesign: design);
    _saveSettings();
  }

  void setThermalDesign(ThermalDesign design) {
    state = state.copyWith(thermalDesign: design);
    _saveSettings();
  }

  void setPDFSave(bool value) {
    state = state.copyWith(isPDFSave: value);
    _saveSettings();
  }

  void setIsPaid(bool value) {
    state = state.copyWith(isPaid: value);
    _saveSettings();
  }

  void setShowPaidStamp(bool value) {
    state = state.copyWith(showPaidStamp: value);
    _saveSettings();
  }

  void setPaidStampText(String value) {
    state = state.copyWith(paidStampText: value);
    _saveSettings();
  }

  void setPaidStampSignature(String value) {
    state = state.copyWith(paidStampSignature: value);
    _saveSettings();
  }

  void setShowDateOnStamp(bool value) {
    state = state.copyWith(showDateOnStamp: value);
    _saveSettings();
  }

  void setShowBackgroundWatermark(bool value) {
    state = state.copyWith(showBackgroundWatermark: value);
    _saveSettings();
  }

  void setWatermarkOpacity(double value) {
    state = state.copyWith(watermarkOpacity: value);
    _saveSettings();
  }

  void setSelectedBankIndex(int value) {
    state = state.copyWith(selectedBankIndex: value);
    _saveSettings();
  }

  void setShowBankDetailsOnBill(bool value) {
    state = state.copyWith(showBankDetailsOnBill: value);
    _saveSettings();
  }

  void setAutoPrintOnSale(bool value) {
    state = state.copyWith(isAutoPrintOnSale: value);
    _saveSettings();
  }

  void setShowTagLine(bool value) {
    state = state.copyWith(isShowTagLine: value);
    _saveSettings();
  }

  void setTagLineInsteadOfCEOName(bool value) {
    state = state.copyWith(isTagLineInsteadOfCEOName: value);
    _saveSettings();
  }

  void setShowUserCard(bool value) {
    state = state.copyWith(isShowUserCard: value);
    _saveSettings();
  }

  void setCardElevation(double value) {
    state = state.copyWith(cardElevation: value);
    _saveSettings();
  }

  void setAppBarElevation(double value) {
    state = state.copyWith(appBarElevation: value);
    _saveSettings();
  }

  void setProductCardElevation(double value) {
    state = state.copyWith(productCardElevation: value);
    _saveSettings();
  }

  Future<void> setDirectoryPath(String newPath) async {
    await _hiveService.setDirectoryPath(newPath);
    state = state.copyWith(directoryPath: newPath);
    _saveSettings();
  }

  void setAppLockEnabled(bool value) {
    state = state.copyWith(isAppLockEnabled: value);
    _saveSettings();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void setUseMultiCart(bool value) {
    state = state.copyWith(useMultiCart: value);
    _saveSettings();
  }

  void setIconStyle(IconStyle style) {
    state = state.copyWith(iconStyle: style);
    _saveSettings();
  }

  void setPrimaryColor(int colorValue) {
    state = state.copyWith(primaryColorValue: colorValue);
    _saveSettings();
  }

  // Module visibility toggles
  void setShowShoppingListModule(bool value) {
    state = state.copyWith(showShoppingListModule: value);
    _saveSettings();
  }

  void setShowRepairsModule(bool value) {
    state = state.copyWith(showRepairsModule: value);
    _saveSettings();
  }

  // Home Page Section Settings Methods
  void setShowBannerSection(bool value) {
    state = state.copyWith(showBannerSection: value);
    _saveSettings();
  }

  void addBannerImage(String imagePath) {
    final newBanners = List<String>.from(state.bannerImagePaths)
      ..add(imagePath);
    state = state.copyWith(bannerImagePaths: newBanners);
    _saveSettings();
  }

  void removeBannerImage(String imagePath) {
    final newBanners = List<String>.from(state.bannerImagePaths)
      ..remove(imagePath);
    state = state.copyWith(bannerImagePaths: newBanners);
    _saveSettings();
  }

  void reorderBannerImages(int oldIndex, int newIndex) {
    final newBanners = List<String>.from(state.bannerImagePaths);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = newBanners.removeAt(oldIndex);
    newBanners.insert(newIndex, item);
    state = state.copyWith(bannerImagePaths: newBanners);
    _saveSettings();
  }

  void setBannerAutoScroll(bool value) {
    state = state.copyWith(bannerAutoScroll: value);
    _saveSettings();
  }

  void setBannerScrollDuration(int value) {
    state = state.copyWith(bannerScrollDuration: value);
    _saveSettings();
  }

  void setShowBrandsSection(bool value) {
    state = state.copyWith(showBrandsSection: value);
    _saveSettings();
  }

  void setShowCategoriesSection(bool value) {
    state = state.copyWith(showCategoriesSection: value);
    _saveSettings();
  }

  void setShowTopSellingSection(bool value) {
    state = state.copyWith(showTopSellingSection: value);
    _saveSettings();
  }

  void setShowLatestItemsSection(bool value) {
    state = state.copyWith(showLatestItemsSection: value);
    _saveSettings();
  }

  void setShowLatestServicesSection(bool value) {
    state = state.copyWith(showLatestServicesSection: value);
    _saveSettings();
  }

  void setShowLowStockSection(bool value) {
    state = state.copyWith(showLowStockSection: value);
    _saveSettings();
  }

  void setProductsPerSection(int value) {
    state = state.copyWith(productsPerSection: value);
    _saveSettings();
  }

  void setSectionOrder(List<String> order) {
    state = state.copyWith(sectionOrder: order);
    _saveSettings();
  }

  void moveSectionUp(String sectionKey) {
    final currentOrder = List<String>.from(state.sectionOrder);
    final index = currentOrder.indexOf(sectionKey);
    if (index > 0) {
      final temp = currentOrder[index - 1];
      currentOrder[index - 1] = currentOrder[index];
      currentOrder[index] = temp;
      setSectionOrder(currentOrder);
    }
  }

  void moveSectionDown(String sectionKey) {
    final currentOrder = List<String>.from(state.sectionOrder);
    final index = currentOrder.indexOf(sectionKey);
    if (index < currentOrder.length - 1) {
      final temp = currentOrder[index + 1];
      currentOrder[index + 1] = currentOrder[index];
      currentOrder[index] = temp;
      setSectionOrder(currentOrder);
    }
  }

  void setTopSellingProductsCount(int value) {
    state = state.copyWith(topSellingProductsCount: value);
    _saveSettings();
  }

  void setLatestItemsCount(int value) {
    state = state.copyWith(latestItemsCount: value);
    _saveSettings();
  }

  void setLatestServicesCount(int value) {
    state = state.copyWith(latestServicesCount: value);
    _saveSettings();
  }

  void setLowStockItemsCount(int value) {
    state = state.copyWith(lowStockItemsCount: value);
    _saveSettings();
  }
}

final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.read(hiveServiceProvider)),
);
