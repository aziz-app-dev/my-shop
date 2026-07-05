import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../database/database_services.dart';
import '../cloudinary/cloudinary_service.dart';
import '../../../models/items_model.dart';
import '../../../models/bills_model.dart';
import '../../../models/coustomer_model.dart';
import '../../../models/user/user_model.dart';
import '../../../models/brand_model.dart';
import '../../../models/category_model.dart';
import '../../../models/shopping_list_model.dart';

/// Backup progress callback
typedef BackupProgressCallback = void Function(double progress, String status);

/// Backup service for Supabase cloud backup and restore
class BackupService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final HiveService _hiveService;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  BackupService(this._hiveService);

  /// Upload image to Cloudinary and return URL
  /// Returns null if upload fails or file doesn't exist
  Future<String?> _uploadImageToCloud(String? localPath, String folder) async {
    if (localPath == null || localPath.isEmpty) return null;

    final file = File(localPath);
    if (!file.existsSync()) {
      debugPrint('Image file not found: $localPath');
      return null;
    }

    // Check if Cloudinary is configured
    if (!_cloudinaryService.isConfigured) {
      debugPrint('Cloudinary not configured, storing local path');
      return localPath; // Fall back to local path
    }

    try {
      final result = await _cloudinaryService.uploadImage(
        file,
        folder: folder,
        maxSizeKB: 800, // Max 800KB
      );

      if (result.success && result.url != null) {
        debugPrint('Image uploaded to Cloudinary: ${result.url}');
        return result.url;
      } else {
        debugPrint('Cloudinary upload failed: ${result.error}');
        return localPath; // Fall back to local path
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return localPath; // Fall back to local path
    }
  }

  /// Get unique device/user identifier for backup
  Future<String> _getBackupId() async {
    final users = _hiveService.getUsers();
    if (users.isNotEmpty) {
      // Use email as unique identifier (single user app)
      final user = users.first;
      final identifier = user.email.replaceAll(RegExp(r'[^\w]'), '_');
      return identifier;
    }
    // Fallback to default if no user
    return 'default_backup';
  }

  /// Create a full backup to Supabase
  Future<bool> createBackup({
    required BackupProgressCallback onProgress,
  }) async {
    try {
      final backupId = await _getBackupId();

      // Calculate total items for progress
      final users = _hiveService.getUsers();
      final products = _hiveService.getProducts();
      final bills = _hiveService.getBills();
      final customers = _hiveService.getCustomers();
      final brands = await _hiveService.getBrands();
      final categories = await _hiveService.getCategories();
      final shoppingLists = await _hiveService.getShoppingLists();

      int totalSteps = 9; // metadata + 7 data types + settings
      int completedSteps = 0;

      void updateProgress(String status) {
        completedSteps++;
        final progress = completedSteps / totalSteps;
        onProgress(progress.clamp(0.0, 1.0), status);
      }

      // 1. Create/Update backup metadata
      onProgress(0.0, 'Starting backup...');
      await _supabase.from('backups').upsert({
        'id': backupId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'device_info': Platform.operatingSystem,
        'status': 'in_progress',
        'items_count': {
          'users': users.length,
          'products': products.length,
          'bills': bills.length,
          'customers': customers.length,
          'brands': brands.length,
          'categories': categories.length,
          'shoppingLists': shoppingLists.length,
        },
      });
      updateProgress('Backup metadata saved');

      // 2. Backup Users (with image uploads to Cloudinary)
      onProgress(
        completedSteps / totalSteps,
        'Backing up profile & uploading images...',
      );
      final List<Map<String, dynamic>> usersData = [];
      for (final user in users) {
        // Upload user images to Cloudinary
        final shopLogoUrl = await _uploadImageToCloud(
          user.shopLogoPath,
          'shop_logos',
        );
        final userImageUrl = await _uploadImageToCloud(
          user.userImagePath,
          'user_images',
        );

        // Upload bank QR codes
        final List<Map<String, dynamic>> bankDetailsData = [];
        for (final bank in user.bankDetails) {
          final qrCodeUrl = await _uploadImageToCloud(
            bank.qrCodePath,
            'qr_codes',
          );
          bankDetailsData.add({
            'bank_name': bank.bankName,
            'account_number': bank.accountNumber,
            'ifsc_code': bank.ifscCode,
            'qr_code_path': qrCodeUrl,
          });
        }

        usersData.add({
          'id': user.id,
          'backup_id': backupId,
          'owner_name': user.ownerName,
          'email': user.email,
          'shop_name': user.shopName,
          'shop_tagline': user.shopTagline,
          'shop_address': user.shopAddress,
          'shop_logo_path': shopLogoUrl,
          'user_image_path': userImageUrl,
          'phone_number': user.phoneNumber,
          'whatsapp': user.whatsapp,
          'facebook': user.facebook,
          'twitter': user.twitter,
          'instagram': user.instagram,
          'bank_details': bankDetailsData,
        });
      }
      if (usersData.isNotEmpty) {
        // Delete old data first
        await _supabase.from('backup_users').delete().eq('backup_id', backupId);
        await _supabase.from('backup_users').insert(usersData);
      }
      updateProgress('Profile backed up');

      // 3. Backup Products (with image uploads to Cloudinary)
      onProgress(
        completedSteps / totalSteps,
        'Backing up products & uploading images...',
      );
      final List<Map<String, dynamic>> productsData = [];
      for (final product in products) {
        // Upload product image to Cloudinary if it's a local path
        String? imageUrl = product.imageUrl;
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = await _uploadImageToCloud(imageUrl, 'products');
        }

        productsData.add({
          'id': product.id,
          'backup_id': backupId,
          'name': product.name,
          'price': product.price,
          'stock': product.stock,
          'description': product.description,
          'image_url': imageUrl,
          'is_service': product.isService,
          'purchase_price': product.purchasePrice,
          'is_backup': product.isBackup,
          'created_at': product.createdAt.toIso8601String(),
          'updated_at': product.updatedAt.toIso8601String(),
          'warranty': product.warranty,
          'condition': product.condition,
          'brand': product.brand,
          'category': product.category,
        });
      }
      if (productsData.isNotEmpty) {
        await _supabase
            .from('backup_products')
            .delete()
            .eq('backup_id', backupId);
        await _supabase.from('backup_products').insert(productsData);
      }
      updateProgress('Products backed up');

      // 4. Backup Bills
      onProgress(completedSteps / totalSteps, 'Backing up bills...');
      final billsData =
          bills
              .map(
                (bill) => {
                  'id': bill.id,
                  'backup_id': backupId,
                  'date_time': bill.dateTime.toIso8601String(),
                  'quantities': bill.quantities,
                  'total_amount': bill.totalAmount,
                  'customer_name': bill.customerName,
                  'customer_id': bill.customerId,
                  'status': bill.status,
                  'payment_method': bill.paymentMethod,
                  'discount': bill.discount,
                  'paid_amount': bill.paidAmount,
                  'items':
                      bill.items
                          .map(
                            (product) => {
                              'id': product.id,
                              'name': product.name,
                              'price': product.price,
                              'stock': product.stock,
                              'description': product.description,
                              'image_url': product.imageUrl,
                              'is_service': product.isService,
                              'purchase_price': product.purchasePrice,
                              'is_backup': product.isBackup,
                              'created_at': product.createdAt.toIso8601String(),
                              'updated_at': product.updatedAt.toIso8601String(),
                              'warranty': product.warranty,
                              'condition': product.condition,
                              'brand': product.brand,
                              'category': product.category,
                            },
                          )
                          .toList(),
                },
              )
              .toList();
      if (billsData.isNotEmpty) {
        await _supabase.from('backup_bills').delete().eq('backup_id', backupId);
        await _supabase.from('backup_bills').insert(billsData);
      }
      updateProgress('Bills backed up');

      // 5. Backup Customers
      onProgress(completedSteps / totalSteps, 'Backing up customers...');
      final customersData =
          customers
              .map(
                (customer) => {
                  'id': customer.id,
                  'backup_id': backupId,
                  'name': customer.name,
                  'address': customer.address,
                  'phone_number': customer.phoneNumber,
                  'visit_count': customer.visitCount,
                  'bill_ids': customer.billIds,
                  'total_pending_amount': customer.totalPendingAmount,
                  'total_paid_amount': customer.totalPaidAmount,
                },
              )
              .toList();
      if (customersData.isNotEmpty) {
        await _supabase
            .from('backup_customers')
            .delete()
            .eq('backup_id', backupId);
        await _supabase.from('backup_customers').insert(customersData);
      }
      updateProgress('Customers backed up');

      // 6. Backup Brands (with image uploads)
      onProgress(completedSteps / totalSteps, 'Backing up brands...');
      final List<Map<String, dynamic>> brandsData = [];
      for (final brand in brands) {
        String? imageUrl = brand.imageUrl;
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = await _uploadImageToCloud(imageUrl, 'brands');
        }
        brandsData.add({
          'id': brand.id,
          'backup_id': backupId,
          'name': brand.name,
          'image_url': imageUrl,
          'created_at': brand.createdAt?.toIso8601String(),
          'updated_at': brand.updatedAt?.toIso8601String(),
        });
      }
      if (brandsData.isNotEmpty) {
        await _supabase
            .from('backup_brands')
            .delete()
            .eq('backup_id', backupId);
        await _supabase.from('backup_brands').insert(brandsData);
      }
      updateProgress('Brands backed up');

      // 7. Backup Categories (with image uploads)
      onProgress(completedSteps / totalSteps, 'Backing up categories...');
      final List<Map<String, dynamic>> categoriesData = [];
      for (final category in categories) {
        String? imageUrl = category.imageUrl;
        if (imageUrl != null && !imageUrl.startsWith('http')) {
          imageUrl = await _uploadImageToCloud(imageUrl, 'categories');
        }
        categoriesData.add({
          'id': category.id,
          'backup_id': backupId,
          'name': category.name,
          'image_url': imageUrl,
          'created_at':
              category.createdAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'updated_at':
              category.updatedAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        });
      }
      if (categoriesData.isNotEmpty) {
        await _supabase
            .from('backup_categories')
            .delete()
            .eq('backup_id', backupId);
        await _supabase.from('backup_categories').insert(categoriesData);
      }
      updateProgress('Categories backed up');

      // 8. Backup Shopping Lists with items (with image uploads)
      onProgress(completedSteps / totalSteps, 'Backing up shopping lists...');
      final List<Map<String, dynamic>> shoppingListsData = [];
      for (final list in shoppingLists) {
        final items = await _hiveService.getShoppingListItems(list.id);
        final List<Map<String, dynamic>> itemsData = [];
        for (final item in items) {
          String? productImageUrl = item.productImageUrl;
          if (productImageUrl != null && !productImageUrl.startsWith('http')) {
            productImageUrl = await _uploadImageToCloud(
              productImageUrl,
              'shopping_items',
            );
          }
          itemsData.add({
            'id': item.id,
            'list_id': item.listId,
            'product_id': item.productId,
            'product_name': item.productName,
            'product_image_url': productImageUrl,
            'quantity_needed': item.quantityNeeded,
            'is_shopped': item.isShopped,
            'price': item.price,
            'brand': item.brand,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
          });
        }
        shoppingListsData.add({
          'id': list.id,
          'backup_id': backupId,
          'name': list.name,
          'created_at': list.createdAt.toIso8601String(),
          'updated_at': list.updatedAt.toIso8601String(),
          'items': itemsData,
        });
      }
      if (shoppingListsData.isNotEmpty) {
        await _supabase
            .from('backup_shopping_lists')
            .delete()
            .eq('backup_id', backupId);
        await _supabase.from('backup_shopping_lists').insert(shoppingListsData);
      }
      updateProgress('Shopping lists backed up');

      // 9. Backup Settings
      onProgress(completedSteps / totalSteps, 'Backing up settings...');
      try {
        final settingsBox = await _hiveService.getSettingsBox();
        final settings = settingsBox.get('settings');
        final fieldConfigs = await _hiveService.getFieldConfigs();
        final customerFieldConfigs =
            await _hiveService.getCustomerFieldConfigs();

        await _supabase.from('backup_settings').upsert({
          'backup_id': backupId,
          'settings':
              settings is Map
                  ? Map<String, dynamic>.from(settings)
                  : {'data': settings},
          'field_configs': fieldConfigs.map(
            (key, value) => MapEntry(key, value.toMap()),
          ),
          'customer_field_configs': customerFieldConfigs.map(
            (key, value) => MapEntry(key, value.toMap()),
          ),
        });
      } catch (e) {
        debugPrint('Error backing up settings: $e');
      }
      updateProgress('Settings backed up');

      // Update backup completion status
      await _supabase
          .from('backups')
          .update({
            'updated_at': DateTime.now().toIso8601String(),
            'status': 'completed',
          })
          .eq('id', backupId);

      onProgress(1.0, 'Backup completed successfully!');
      return true;
    } catch (e) {
      debugPrint('Backup error: $e');
      onProgress(-1, 'Backup failed: ${e.toString()}');
      return false;
    }
  }

  /// Restore backup from Supabase
  Future<bool> restoreBackup({
    required BackupProgressCallback onProgress,
    String? customBackupId,
  }) async {
    try {
      final backupId = customBackupId ?? await _getBackupId();

      onProgress(0.0, 'Checking for backup...');

      // Check if backup exists
      final backupData =
          await _supabase
              .from('backups')
              .select()
              .eq('id', backupId)
              .maybeSingle();

      if (backupData == null) {
        onProgress(-1, 'No backup found');
        return false;
      }

      int totalSteps = 7;
      int completedSteps = 0;

      void updateProgress(String status) {
        completedSteps++;
        final progress = completedSteps / totalSteps;
        onProgress(progress.clamp(0.0, 1.0), status);
      }

      // 1. Restore Users
      onProgress(0.1, 'Restoring profile...');
      final usersData = await _supabase
          .from('backup_users')
          .select()
          .eq('backup_id', backupId);
      for (final userData in usersData) {
        final user = User.fromMap(_convertUserFromSupabase(userData));
        await _hiveService.saveUser(user);
      }
      updateProgress('Profile restored');

      // 2. Restore Products
      onProgress(completedSteps / totalSteps, 'Restoring products...');
      final productsData = await _supabase
          .from('backup_products')
          .select()
          .eq('backup_id', backupId);
      for (final productData in productsData) {
        final product = Product.fromMap(
          _convertProductFromSupabase(productData),
        );
        await _hiveService.addProduct(product);
      }
      updateProgress('Products restored');

      // 3. Restore Customers
      onProgress(completedSteps / totalSteps, 'Restoring customers...');
      final customersData = await _supabase
          .from('backup_customers')
          .select()
          .eq('backup_id', backupId);
      for (final customerData in customersData) {
        final customer = Customer.fromMap(
          _convertCustomerFromSupabase(customerData),
        );
        await _hiveService.saveCustomer(customer);
      }
      updateProgress('Customers restored');

      // 4. Restore Bills
      onProgress(completedSteps / totalSteps, 'Restoring bills...');
      final billsData = await _supabase
          .from('backup_bills')
          .select()
          .eq('backup_id', backupId);
      for (final billData in billsData) {
        final bill = Bill.fromMap(_convertBillFromSupabase(billData));
        await _hiveService.saveBill(bill);
      }
      updateProgress('Bills restored');

      // 5. Restore Brands
      onProgress(completedSteps / totalSteps, 'Restoring brands...');
      final brandsData = await _supabase
          .from('backup_brands')
          .select()
          .eq('backup_id', backupId);
      for (final brandData in brandsData) {
        final brand = Brand.fromMap(_convertBrandFromSupabase(brandData));
        await _hiveService.addBrand(brand);
      }
      updateProgress('Brands restored');

      // 6. Restore Categories
      onProgress(completedSteps / totalSteps, 'Restoring categories...');
      final categoriesData = await _supabase
          .from('backup_categories')
          .select()
          .eq('backup_id', backupId);
      for (final categoryData in categoriesData) {
        final category = Category.fromMap(
          _convertCategoryFromSupabase(categoryData),
        );
        await _hiveService.addCategory(category);
      }
      updateProgress('Categories restored');

      // 7. Restore Shopping Lists
      onProgress(completedSteps / totalSteps, 'Restoring shopping lists...');
      final shoppingListsData = await _supabase
          .from('backup_shopping_lists')
          .select()
          .eq('backup_id', backupId);
      for (final listData in shoppingListsData) {
        final list = ShoppingList(
          id: listData['id'],
          name: listData['name'],
          createdAt:
              DateTime.tryParse(listData['created_at'] ?? '') ?? DateTime.now(),
          updatedAt:
              DateTime.tryParse(listData['updated_at'] ?? '') ?? DateTime.now(),
        );
        await _hiveService.createShoppingList(list);

        // Restore items for this list
        final items = listData['items'] as List<dynamic>? ?? [];
        for (final itemData in items) {
          final item = ShoppingListItem(
            id: itemData['id'],
            listId: itemData['list_id'],
            productId: itemData['product_id'],
            productName: itemData['product_name'],
            productImageUrl: itemData['product_image_url'],
            quantityNeeded:
                itemData['quantity_needed'] is int
                    ? itemData['quantity_needed']
                    : int.tryParse(
                          itemData['quantity_needed']?.toString() ?? '1',
                        ) ??
                        1,
            isShopped: _toBool(itemData['is_shopped']),
            price: (itemData['price'] as num?)?.toDouble() ?? 0.0,
            brand: itemData['brand'],
            createdAt:
                DateTime.tryParse(itemData['created_at'] ?? '') ??
                DateTime.now(),
            updatedAt:
                DateTime.tryParse(itemData['updated_at'] ?? '') ??
                DateTime.now(),
          );
          await _hiveService.addToShoppingList(item);
        }
      }
      updateProgress('Shopping lists restored');

      onProgress(1.0, 'Restore completed successfully!');
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      onProgress(-1, 'Restore failed: ${e.toString()}');
      return false;
    }
  }

  /// Convert user data from Supabase format
  Map<String, dynamic> _convertUserFromSupabase(Map<String, dynamic> data) {
    final bankDetails =
        (data['bank_details'] as List<dynamic>? ?? [])
            .map(
              (bank) => {
                'bankName': bank['bank_name'],
                'accountNumber': bank['account_number'],
                'ifscCode': bank['ifsc_code'],
                'qrCodePath': bank['qr_code_path'],
              },
            )
            .toList();

    return {
      'id': data['id'],
      'ownerName': data['owner_name'],
      'email': data['email'],
      'shopName': data['shop_name'],
      'shopTagline': data['shop_tagline'],
      'shopAddress': data['shop_address'],
      'shopLogoPath': data['shop_logo_path'],
      'userImagePath': data['user_image_path'],
      'phoneNumber': data['phone_number'],
      'whatsapp': data['whatsapp'],
      'facebook': data['facebook'],
      'twitter': data['twitter'],
      'instagram': data['instagram'],
      'bankDetails': bankDetails,
    };
  }

  /// Helper to convert value to bool (handles string "true"/"false" from Supabase)
  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return false;
  }

  /// Convert product data from Supabase format
  Map<String, dynamic> _convertProductFromSupabase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'price': data['price'],
      'stock': data['stock'],
      'description': data['description'],
      'imageUrl': data['image_url'],
      'isService': _toBool(data['is_service']),
      'purchasePrice': data['purchase_price'],
      'isBackup': _toBool(data['is_backup']),
      'createdAt': data['created_at'],
      'updatedAt': data['updated_at'],
      'warranty': _toBool(data['warranty']),
      'condition': data['condition'],
      'brand': data['brand'],
      'category': data['category'],
    };
  }

  /// Convert customer data from Supabase format
  Map<String, dynamic> _convertCustomerFromSupabase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'address': data['address'],
      'phoneNumber': data['phone_number'],
      'visitCount': data['visit_count'] ?? 0,
      'billIds': data['bill_ids'] ?? [],
      'totalPendingAmount': data['total_pending_amount'] ?? 0,
      'totalPaidAmount': data['total_paid_amount'] ?? 0,
    };
  }

  /// Convert bill data from Supabase format
  Map<String, dynamic> _convertBillFromSupabase(Map<String, dynamic> data) {
    final items =
        (data['items'] as List<dynamic>? ?? []).map((item) {
          return {
            'id': item['id'],
            'name': item['name'],
            'price': item['price'],
            'stock': item['stock'],
            'description': item['description'],
            'imageUrl': item['image_url'],
            'isService': _toBool(item['is_service']),
            'purchasePrice': item['purchase_price'],
            'isBackup': _toBool(item['is_backup']),
            'createdAt': item['created_at'],
            'updatedAt': item['updated_at'],
            'warranty': _toBool(item['warranty']),
            'condition': item['condition'],
            'brand': item['brand'],
            'category': item['category'],
          };
        }).toList();

    return {
      'id': data['id'],
      'dateTime': data['date_time'],
      'quantities': data['quantities'],
      'totalAmount': data['total_amount'],
      'customerName': data['customer_name'],
      'customerId': data['customer_id'],
      'status': data['status'],
      'paymentMethod': data['payment_method'],
      'discount': data['discount'],
      'paidAmount': data['paid_amount'],
      'items': items,
    };
  }

  /// Convert brand data from Supabase format
  Map<String, dynamic> _convertBrandFromSupabase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'imageUrl': data['image_url'],
      'createdAt': data['created_at'],
      'updatedAt': data['updated_at'],
    };
  }

  /// Convert category data from Supabase format
  Map<String, dynamic> _convertCategoryFromSupabase(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'imageUrl': data['image_url'],
      'createdAt': data['created_at'],
      'updatedAt': data['updated_at'],
    };
  }

  /// Get last backup info
  Future<Map<String, dynamic>?> getLastBackupInfo() async {
    try {
      final backupId = await _getBackupId();
      final backupData =
          await _supabase
              .from('backups')
              .select()
              .eq('id', backupId)
              .maybeSingle();

      if (backupData != null) {
        return {
          'updatedAt':
              backupData['updated_at'] != null
                  ? DateTime.parse(backupData['updated_at'])
                  : null,
          'itemsCount': backupData['items_count'],
          'status': backupData['status'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Get backup info error: $e');
      return null;
    }
  }

  /// Check if backup exists
  Future<bool> hasBackup() async {
    try {
      final backupId = await _getBackupId();
      final backupData =
          await _supabase
              .from('backups')
              .select('id')
              .eq('id', backupId)
              .maybeSingle();
      return backupData != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if backup exists for a specific backup ID
  Future<bool> hasBackupForId(String backupId) async {
    try {
      final backupData =
          await _supabase
              .from('backups')
              .select('id')
              .eq('id', backupId)
              .maybeSingle();
      return backupData != null;
    } catch (e) {
      return false;
    }
  }

  /// Get backup info for a specific backup ID
  Future<Map<String, dynamic>?> getBackupInfoForId(String backupId) async {
    try {
      final backupData =
          await _supabase
              .from('backups')
              .select()
              .eq('id', backupId)
              .maybeSingle();

      if (backupData != null) {
        return {
          'updatedAt':
              backupData['updated_at'] != null
                  ? DateTime.parse(backupData['updated_at'])
                  : null,
          'itemsCount': backupData['items_count'],
          'status': backupData['status'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Get backup info error: $e');
      return null;
    }
  }
}
