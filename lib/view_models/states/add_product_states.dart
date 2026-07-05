import 'dart:io';

import '../../models/items_model.dart';

class ProductFormState {
  final String? name;
  final double? price;
  final int? stock;
  final String? description;
  final File? imageFile;
  final bool isLoading;
  final String? errorMessage;
  final bool? isService;
  final double? purchasePrice;
  final bool? isBackup;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? warranty;
  final String? condition;
  final String? brand;
  final String? category;
  final String? barcode;
  final Map<String, FieldConfig> fieldConfigs;
  final Map<String, bool> fieldErrors; // Added field errors state

  ProductFormState({
    this.name,
    this.price,
    this.stock,
    this.description,
    this.imageFile,
    this.isLoading = false,
    this.errorMessage,
    this.isService = false,
    this.purchasePrice,
    this.isBackup = false,
    this.createdAt,
    this.updatedAt,
    this.warranty = false,
    this.condition,
    this.brand,
    this.category,
    this.barcode,
    Map<String, FieldConfig>? fieldConfigs,
    Map<String, bool>? fieldErrors,
  })  : fieldConfigs =
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
            },
        fieldErrors =
            fieldErrors ??
            {
              'name': false,
              'price': false,
              'purchasePrice': false,
              'stock': false,
              'condition': false,
              'brand': false,
              'category': false,
              'description': false,
              'barcode': false,
            };

  ProductFormState copyWith({
    String? name,
    double? price,
    int? stock,
    String? description,
    File? imageFile,
    bool? isLoading,
    String? errorMessage,
    bool? isService,
    double? purchasePrice,
    bool? isBackup,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? warranty,
    String? condition,
    String? brand,
    String? category,
    String? barcode,
    Map<String, FieldConfig>? fieldConfigs,
    Map<String, bool>? fieldErrors,
  }) {
    return ProductFormState(
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageFile: imageFile ?? this.imageFile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isService: isService ?? this.isService,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      isBackup: isBackup ?? this.isBackup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      warranty: warranty ?? this.warranty,
      condition: condition ?? this.condition,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      fieldConfigs: fieldConfigs ?? this.fieldConfigs,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
