// models/items_model.dart
enum WidgetType { textField, dropdown, checkbox, imagePicker }

class FieldConfig {
  final String title;
  final bool isShow;
  final bool isRequired;
  final String hintText;
  final String validatorText;
  final WidgetType widgetType;

  FieldConfig({
    required this.title,
    required this.isShow,
    required this.isRequired,
    required this.hintText,
    required this.validatorText,
    required this.widgetType,
  });

  // Initial constructor
  factory FieldConfig.initial(String fieldName, WidgetType widgetType) {
    return FieldConfig(
      title: _getDefaultTitle(fieldName),
      isShow: true,
      isRequired: _getDefaultRequired(fieldName),
      hintText: _getDefaultHint(fieldName),
      validatorText: _getDefaultValidator(fieldName),
      widgetType: widgetType,
    );
  }

  // From map for deserialization
  factory FieldConfig.fromMap(Map<String, dynamic> map) {
    return FieldConfig(
      title: map['title'] ?? '',
      isShow: map['isShow'] ?? true,
      isRequired: map['isRequired'] ?? false,
      hintText: map['hintText'] ?? '',
      validatorText: map['validatorText'] ?? '',
      widgetType: WidgetType.values[map['widgetType'] ?? 0],
    );
  }

  // To map for serialization
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isShow': isShow,
      'isRequired': isRequired,
      'hintText': hintText,
      'validatorText': validatorText,
      'widgetType': widgetType.index,
    };
  }

  FieldConfig copyWith({
    String? title,
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    WidgetType? widgetType,
  }) {
    return FieldConfig(
      title: title ?? this.title,
      isShow: isShow ?? this.isShow,
      isRequired: isRequired ?? this.isRequired,
      hintText: hintText ?? this.hintText,
      validatorText: validatorText ?? this.validatorText,
      widgetType: widgetType ?? this.widgetType,
    );
  }

  static String _getDefaultTitle(String fieldName) {
    final titles = {
      'name': 'Product Name',
      'price': 'Price',
      'imageFile': 'Product Image',
      'warranty': 'Warranty',
      'condition': 'Condition',
      'brand': 'Brand',
      'description': 'Description',
      'purchasePrice': 'Purchase Price',
      'stock': 'Stock Quantity',
      'isBackup': 'Backup Item',
    };
    return titles[fieldName] ?? fieldName;
  }

  static bool _getDefaultRequired(String fieldName) {
    return fieldName == 'name' || fieldName == 'price';
  }

  static String _getDefaultHint(String fieldName) {
    final hints = {
      'name': 'Enter product name',
      'price': 'Enter price',
      'imageFile': 'Tap to select image',
      'warranty': 'Select warranty option',
      'condition': 'Select product condition',
      'brand': 'Enter brand name',
      'description': 'Enter product description',
      'purchasePrice': 'Enter purchase price',
      'stock': 'Enter stock quantity',
      'isBackup': 'Mark as backup item',
    };
    return hints[fieldName] ?? 'Enter value';
  }

  static String _getDefaultValidator(String fieldName) {
    final validators = {
      'name': 'Product name is required',
      'price': 'Valid price is required',
      'imageFile': 'Product image is required',
      'warranty': 'Warranty selection is required',
      'condition': 'Condition selection is required',
      'brand': 'Brand name is required',
      'description': 'Description is required',
      'purchasePrice': 'Purchase price is required',
      'stock': 'Stock quantity is required',
      'isBackup': '',
    };
    return validators[fieldName] ?? 'This field is required';
  }
}
