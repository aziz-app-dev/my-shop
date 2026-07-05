import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/items_model.dart';
import '../../utils/image_picker_helper.dart';
import '../services/database/database_services.dart';
import '../services/cloudinary/cloudinary_service.dart';
import '../states/add_product_states.dart';
import 'product_view.dart';
import 'home_page_provider.dart';

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final DatabaseService _databaseService;
  final Product? initialProduct;
  final Ref _ref;

  ProductFormNotifier(this._databaseService, this._ref, {this.initialProduct})
    : super(
        ProductFormState(
          name: initialProduct?.name,
          price: initialProduct?.price,
          stock: initialProduct?.stock,
          description: initialProduct?.description,
          imageFile:
              initialProduct?.imageUrl != null
                  ? File(initialProduct!.imageUrl!)
                  : null,
          isService: initialProduct?.isService ?? false,
          purchasePrice: initialProduct?.purchasePrice,
          isBackup: initialProduct?.isBackup ?? false,
          createdAt: initialProduct?.createdAt,
          updatedAt: initialProduct?.updatedAt,
          warranty: initialProduct?.warranty ?? false,
          condition: initialProduct?.condition,
          brand: initialProduct?.brand,
          category: initialProduct?.category,
          barcode: initialProduct?.barcode,
          fieldConfigs:
              initialProduct?.fieldConfigs ?? _loadDefaultFieldConfigs(),
        ),
      );

  // Load default field configurations (could be from DatabaseService)
  static Map<String, FieldConfig> _loadDefaultFieldConfigs() {
    return {
      'name': FieldConfig.initial('name', WidgetType.textField),
      'price': FieldConfig.initial('price', WidgetType.textField),
      'imageFile': FieldConfig.initial('imageFile', WidgetType.imagePicker),
      'warranty': FieldConfig.initial('warranty', WidgetType.dropdown),
      'condition': FieldConfig.initial('condition', WidgetType.dropdown),
      'brand': FieldConfig.initial('brand', WidgetType.textField),
      'category': FieldConfig.initial('category', WidgetType.dropdown),
      'description': FieldConfig.initial('description', WidgetType.textField),
      'purchasePrice': FieldConfig.initial(
        'purchasePrice',
        WidgetType.textField,
      ),
      'stock': FieldConfig.initial('stock', WidgetType.textField),
      'isBackup': FieldConfig.initial('isBackup', WidgetType.checkbox),
      'barcode': FieldConfig.initial('barcode', WidgetType.textField),
    };
  }

  // Field error validation methods
  void validateField(String fieldName) {
    final fieldConfigs = state.fieldConfigs;
    final fieldErrors = Map<String, bool>.from(state.fieldErrors);

    switch (fieldName) {
      case 'name':
        fieldErrors['name'] =
            fieldConfigs['name']!.isRequired &&
            (state.name == null || state.name!.isEmpty);
        break;
      case 'price':
        fieldErrors['price'] =
            fieldConfigs['price']!.isRequired &&
            (state.price == null || state.price! <= 0);
        break;
      case 'purchasePrice':
        fieldErrors['purchasePrice'] =
            fieldConfigs['purchasePrice']!.isRequired &&
            (state.purchasePrice == null || state.purchasePrice! <= 0);
        break;
      case 'stock':
        fieldErrors['stock'] =
            fieldConfigs['stock']!.isRequired &&
            (state.stock == null || state.stock! < 0);
        break;
      case 'condition':
        fieldErrors['condition'] =
            fieldConfigs['condition']!.isRequired && state.condition == null;
        break;
      case 'brand':
        fieldErrors['brand'] =
            fieldConfigs['brand']!.isRequired &&
            (state.brand == null || state.brand!.isEmpty);
        break;
      case 'description':
        fieldErrors['description'] =
            fieldConfigs['description']!.isRequired &&
            (state.description == null || state.description!.isEmpty);
        break;
      case 'barcode':
        fieldErrors['barcode'] =
            fieldConfigs['barcode']!.isRequired &&
            (state.barcode == null || state.barcode!.isEmpty);
        break;
    }

    state = state.copyWith(fieldErrors: fieldErrors);
  }

  void validateAllFields() {
    final fieldConfigs = state.fieldConfigs;
    final fieldErrors = {
      'name':
          fieldConfigs['name']!.isRequired &&
          (state.name == null || state.name!.isEmpty),
      'price':
          fieldConfigs['price']!.isRequired &&
          (state.price == null || state.price! <= 0),
      'purchasePrice':
          fieldConfigs['purchasePrice']!.isRequired &&
          (state.purchasePrice == null || state.purchasePrice! <= 0),
      'stock':
          fieldConfigs['stock']!.isRequired &&
          (state.stock == null || state.stock! < 0),
      'condition':
          fieldConfigs['condition']!.isRequired && state.condition == null,
      'brand':
          fieldConfigs['brand']!.isRequired &&
          (state.brand == null || state.brand!.isEmpty),
      'description':
          fieldConfigs['description']!.isRequired &&
          (state.description == null || state.description!.isEmpty),
      'barcode':
          fieldConfigs['barcode']!.isRequired &&
          (state.barcode == null || state.barcode!.isEmpty),
    };

    state = state.copyWith(fieldErrors: fieldErrors);
  }

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
    validateField('name');
  }

  void updatePrice(String price) {
    final parsedPrice = double.tryParse(price);
    state = state.copyWith(price: parsedPrice, errorMessage: null);
    validateField('price');
  }

  void updateStock(String stock) {
    final parsedStock = int.tryParse(stock);
    state = state.copyWith(stock: parsedStock, errorMessage: null);
    validateField('stock');
  }

  void updateDescription(String description) {
    state = state.copyWith(
      description: description.isEmpty ? null : description,
      errorMessage: null,
    );
    validateField('description');
  }

  void updateIsService(bool value) {
    state = state.copyWith(
      isService: value,
      stock: value ? null : state.stock,
      purchasePrice: value ? null : state.purchasePrice,
      condition: value ? null : state.condition,
      brand: value ? null : state.brand,
      errorMessage: null,
    );
  }

  void updatePurchasePrice(String price) {
    final parsedPrice = double.tryParse(price);
    state = state.copyWith(purchasePrice: parsedPrice, errorMessage: null);
    validateField('purchasePrice');
  }

  void updateIsBackup(bool value) {
    state = state.copyWith(isBackup: value, errorMessage: null);
  }

  void updateWarranty(bool value) {
    state = state.copyWith(warranty: value, errorMessage: null);
  }

  void updateCondition(String? value) {
    state = state.copyWith(condition: value, errorMessage: null);
    validateField('condition');
  }

  void updateBrand(String brand) {
    state = state.copyWith(
      brand: brand.isEmpty ? null : brand,
      errorMessage: null,
    );
    validateField('brand');
  }

  void updateCategory(String category) {
    state = state.copyWith(
      category: category.isEmpty ? null : category,
      errorMessage: null,
    );
    validateField('category');
  }

  void updateBarcode(String barcode) {
    state = state.copyWith(
      barcode: barcode.isEmpty ? null : barcode,
      errorMessage: null,
    );
    validateField('barcode');
  }

  void updateImageFile(File? file) {
    state = state.copyWith(imageFile: file, errorMessage: null);
  }

  void updateFieldConfig(
    String fieldName, {
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    String? title,
    WidgetType? widgetType,
  }) {
    final updatedConfigs = Map<String, FieldConfig>.from(state.fieldConfigs);
    updatedConfigs[fieldName] = updatedConfigs[fieldName]!.copyWith(
      isShow: isShow,
      isRequired: isRequired,
      hintText: hintText,
      validatorText: validatorText,
      title: title,
      widgetType: widgetType,
    );
    state = state.copyWith(fieldConfigs: updatedConfigs);
    _saveFieldConfigs(updatedConfigs); // Persist changes
  }

  Future<void> _saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
    try {
      await _databaseService.saveFieldConfigs(fieldConfigs);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save field configs: $e');
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (pickedFile != null) {
      // Copy file to app documents directory to avoid Android scoped storage issues
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final savedFile = await pickedFile.copy('${imagesDir.path}/$fileName');
      state = state.copyWith(imageFile: savedFile);
    }
  }

  Future<bool> submitForm() async {
    final fieldConfigs = state.fieldConfigs;
    if (fieldConfigs['name']!.isRequired &&
        (state.name == null || state.name!.isEmpty)) {
      state = state.copyWith(errorMessage: fieldConfigs['name']!.validatorText);
      return false;
    }
    if (fieldConfigs['price']!.isRequired &&
        (state.price == null || state.price! <= 0)) {
      state = state.copyWith(
        errorMessage: fieldConfigs['price']!.validatorText,
      );
      return false;
    }
    if (fieldConfigs['imageFile']!.isRequired &&
        state.imageFile == null &&
        initialProduct?.imageUrl == null) {
      state = state.copyWith(
        errorMessage: fieldConfigs['imageFile']!.validatorText,
      );
      return false;
    }
    if (!(state.isService ?? false)) {
      if (fieldConfigs['purchasePrice']!.isRequired &&
          (state.purchasePrice == null || state.purchasePrice! <= 0)) {
        state = state.copyWith(
          errorMessage: fieldConfigs['purchasePrice']!.validatorText,
        );
        return false;
      }
      if (fieldConfigs['stock']!.isRequired &&
          (state.stock == null || state.stock! < 0)) {
        state = state.copyWith(
          errorMessage: fieldConfigs['stock']!.validatorText,
        );
        return false;
      }
      if (fieldConfigs['condition']!.isRequired && state.condition == null) {
        state = state.copyWith(
          errorMessage: fieldConfigs['condition']!.validatorText,
        );
        return false;
      }
      if (fieldConfigs['brand']!.isRequired &&
          (state.brand == null || state.brand!.isEmpty)) {
        state = state.copyWith(
          errorMessage: fieldConfigs['brand']!.validatorText,
        );
        return false;
      }
    }
    if (fieldConfigs['description']!.isRequired &&
        (state.description == null || state.description!.isEmpty)) {
      state = state.copyWith(
        errorMessage: fieldConfigs['description']!.validatorText,
      );
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();
      String? imageUrl = initialProduct?.imageUrl;

      // Upload image to Cloudinary if a new image was selected
      if (state.imageFile != null) {
        final cloudinaryService = CloudinaryService();

        if (cloudinaryService.isConfigured) {
          final uploadResult = await cloudinaryService.uploadImage(
            state.imageFile!,
            folder: 'products',
          );

          if (uploadResult.success && uploadResult.url != null) {
            imageUrl = uploadResult.url;
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Failed to upload image: ${uploadResult.error}',
            );
            return false;
          }
        } else {
          // Fallback to local path if Cloudinary is not configured
          imageUrl = state.imageFile!.path;
        }
      }

      final product = Product(
        id:
            initialProduct?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: state.name!,
        price: state.price!,
        stock: state.isService ?? false ? null : state.stock,
        description: state.description,
        imageUrl: imageUrl,
        isService: state.isService ?? false,
        purchasePrice: state.isService ?? false ? null : state.purchasePrice,
        isBackup: false,
        createdAt: initialProduct?.createdAt ?? now,
        updatedAt: now,
        warranty: false,
        condition: state.isService ?? false ? null : state.condition,
        brand: state.isService ?? false ? null : state.brand,
        category: state.category,
        barcode: state.barcode,
        fieldConfigs: state.fieldConfigs,
      );

      if (initialProduct == null) {
        await _databaseService.addProduct(product);
      } else {
        await _databaseService.updateProduct(product);
      }

      // Refresh products in all providers to update UI across the app
      _ref.read(productsNotifierProvider.notifier).refreshProducts();
      _ref.read(homePageProvider.notifier).refreshProducts();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save item: $e',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> deleteProduct() async {
    if (initialProduct == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      await _databaseService.deleteProduct(initialProduct!.id);

      // Refresh products in all providers to update UI across the app
      _ref.read(productsNotifierProvider.notifier).refreshProducts();
      _ref.read(homePageProvider.notifier).refreshProducts();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete item: $e',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void resetForm() {
    state = ProductFormState(
      name: null,
      price: null,
      stock: null,
      description: null,
      imageFile: null,
      isService: false,
      purchasePrice: null,
      isBackup: false,
      createdAt: null,
      updatedAt: null,
      warranty: false,
      condition: null,
      brand: null,
      category: null,
      barcode: null,
      fieldConfigs: _loadDefaultFieldConfigs(),
    );
  }
}

final productFormProvider = StateNotifierProvider.family<
  ProductFormNotifier,
  ProductFormState,
  Product?
>(
  (ref, product) => ProductFormNotifier(
    ref.read(databaseServiceProvider),
    ref,
    initialProduct: product,
  ),
);

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);
