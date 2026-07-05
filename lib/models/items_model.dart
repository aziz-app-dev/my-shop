enum WidgetType { textField, dropdown, checkbox, imagePicker }

class FieldConfig {
  final bool isShow;
  final bool isRequired;
  final String hintText;
  final String validatorText;
  final String title;
  final WidgetType widgetType;

  FieldConfig({
    required this.isShow,
    required this.isRequired,
    required this.hintText,
    required this.validatorText,
    required this.title,
    required this.widgetType,
  });

  factory FieldConfig.initial(String fieldName, WidgetType widgetType) {
    String defaultTitle;
    String defaultHintText;
    String defaultValidatorText;

    switch (fieldName) {
      case 'name':
        defaultTitle = 'Item Name';
        defaultHintText = 'Enter item name';
        defaultValidatorText = 'Name is required';
        break;
      case 'price':
        defaultTitle = 'Price';
        defaultHintText = 'Enter price in Rs';
        defaultValidatorText = 'Valid price is required';
        break;
      case 'imageFile':
        defaultTitle = 'Image';
        defaultHintText = 'Tap to select an image';
        defaultValidatorText = 'Image is required';
        break;
      case 'warranty':
        defaultTitle = 'Warranty';
        defaultHintText = 'Select warranty status';
        defaultValidatorText = 'Please select warranty status';
        break;
      case 'condition':
        defaultTitle = 'Condition';
        defaultHintText = 'Select condition';
        defaultValidatorText = 'Please select condition';
        break;
      case 'brand':
        defaultTitle = 'Brand';
        defaultHintText = 'Enter brand name';
        defaultValidatorText = 'Brand is required';
        break;
      case 'description':
        defaultTitle = 'Description';
        defaultHintText = 'Enter description';
        defaultValidatorText = 'Description is required';
        break;
      case 'purchasePrice':
        defaultTitle = 'Purchase Price';
        defaultHintText = 'Enter purchase price in Rs';
        defaultValidatorText = 'Valid purchase price is required';
        break;
      case 'stock':
        defaultTitle = 'Stock Quantity';
        defaultHintText = 'Enter stock quantity';
        defaultValidatorText = 'Valid stock quantity is required';
        break;
      case 'isBackup':
        defaultTitle = 'Enable Backup';
        defaultHintText = '';
        defaultValidatorText = '';
        break;
      case 'barcode':
        defaultTitle = 'Barcode';
        defaultHintText = 'Enter or scan barcode';
        defaultValidatorText = 'Barcode is required';
        break;
      default:
        defaultTitle = fieldName;
        defaultHintText = 'Enter $fieldName';
        defaultValidatorText = '$fieldName is required';
    }

    return FieldConfig(
      isShow: true,
      isRequired:
          fieldName == 'name' ||
          fieldName == 'price' ||
          fieldName == 'imageFile',
      hintText: defaultHintText,
      validatorText: defaultValidatorText,
      title: defaultTitle,
      widgetType: widgetType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isShow': isShow,
      'isRequired': isRequired,
      'hintText': hintText,
      'validatorText': validatorText,
      'title': title,
      'widgetType': widgetType.toString(),
    };
  }

  factory FieldConfig.fromMap(Map<String, dynamic> map) {
    return FieldConfig(
      isShow: map['isShow'] ?? true,
      isRequired: map['isRequired'] ?? false,
      hintText: map['hintText'] ?? '',
      validatorText: map['validatorText'] ?? '',
      title: map['title'] ?? '',
      widgetType: WidgetType.values.firstWhere(
        (e) => e.toString() == map['widgetType'],
        orElse: () => WidgetType.textField,
      ),
    );
  }

  FieldConfig copyWith({
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    String? title,
    WidgetType? widgetType,
  }) {
    return FieldConfig(
      isShow: isShow ?? this.isShow,
      isRequired: isRequired ?? this.isRequired,
      hintText: hintText ?? this.hintText,
      validatorText: validatorText ?? this.validatorText,
      title: title ?? this.title,
      widgetType: widgetType ?? this.widgetType,
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final int? stock;
  final String? description;
  final String? imageUrl;
  final bool isService;
  final double? purchasePrice;
  final bool isBackup;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool warranty;
  final String? condition;
  final String? brand;
  final String? category;
  final String? barcode;
  final Map<String, FieldConfig> fieldConfigs;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.stock,
    this.description,
    this.imageUrl,
    this.isService = false,
    this.purchasePrice,
    this.isBackup = false,
    required this.createdAt,
    required this.updatedAt,
    this.warranty = false,
    this.condition,
    this.brand,
    this.category,
    this.barcode,
    Map<String, FieldConfig>? fieldConfigs,
  }) : fieldConfigs =
           fieldConfigs ??
           {
             'name': FieldConfig.initial('name', WidgetType.textField),
             'price': FieldConfig.initial('price', WidgetType.textField),
             'imageFile': FieldConfig.initial(
               'imageFile',
               WidgetType.imagePicker,
             ),
             'warranty': FieldConfig.initial('warranty', WidgetType.dropdown),
             'condition': FieldConfig.initial('condition', WidgetType.dropdown),
             'brand': FieldConfig.initial('brand', WidgetType.textField),
             'category': FieldConfig.initial('category', WidgetType.dropdown),
             'description': FieldConfig.initial(
               'description',
               WidgetType.textField,
             ),
             'purchasePrice': FieldConfig.initial(
               'purchasePrice',
               WidgetType.textField,
             ),
             'stock': FieldConfig.initial('stock', WidgetType.textField),
             'isBackup': FieldConfig.initial('isBackup', WidgetType.checkbox),
             'barcode': FieldConfig.initial('barcode', WidgetType.textField),
           };

  /// Helper to convert value to bool (handles string "true"/"false" and int 0/1)
  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final fieldConfigsMap = Map<String, dynamic>.from(
      map['fieldConfigs'] ?? {},
    );

    // Start with default configs to ensure all keys exist
    final defaultConfigs = <String, FieldConfig>{
      'name': FieldConfig.initial('name', WidgetType.textField),
      'price': FieldConfig.initial('price', WidgetType.textField),
      'imageFile': FieldConfig.initial('imageFile', WidgetType.imagePicker),
      'warranty': FieldConfig.initial('warranty', WidgetType.dropdown),
      'condition': FieldConfig.initial('condition', WidgetType.dropdown),
      'brand': FieldConfig.initial('brand', WidgetType.textField),
      'category': FieldConfig.initial('category', WidgetType.dropdown),
      'description': FieldConfig.initial('description', WidgetType.textField),
      'purchasePrice': FieldConfig.initial('purchasePrice', WidgetType.textField),
      'stock': FieldConfig.initial('stock', WidgetType.textField),
      'isBackup': FieldConfig.initial('isBackup', WidgetType.checkbox),
      'barcode': FieldConfig.initial('barcode', WidgetType.textField),
    };

    // Override defaults with loaded configs
    for (final entry in fieldConfigsMap.entries) {
      defaultConfigs[entry.key] = FieldConfig.fromMap(
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int?,
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      isService: _toBool(map['isService']),
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble(),
      isBackup: _toBool(map['isBackup']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      warranty: _toBool(map['warranty']),
      condition: map['condition'] as String?,
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      barcode: map['barcode'] as String?,
      fieldConfigs: defaultConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'imageUrl': imageUrl,
      'isService': isService,
      'purchasePrice': purchasePrice,
      'isBackup': isBackup,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'warranty': warranty,
      'condition': condition,
      'brand': brand,
      'category': category,
      'barcode': barcode,
      'fieldConfigs': fieldConfigs.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }
}
