// ignore_for_file: unnecessary_null_aware_assignments

import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/bills_model.dart';
import '../../../models/coustomer_model.dart';
import '../../../models/items_model.dart';
import '../../../models/brand_model.dart';
import '../../../models/category_model.dart';
import '../../../models/shopping_list_model.dart';
import '../../../models/repair_model.dart';
import '../../../models/user/user_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/local_purchase_model.dart';
import '../firebase/firebase_service.dart';
import '../sync/sync_queue.dart';

// Conditional import for path_provider (only used on non-web platforms)
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'database_services_web_stub.dart';

// Conditional import for dart:io
import 'dart:io' if (dart.library.html) 'database_services_web_stub.dart';

/// Riverpod provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Riverpod provider for DatabaseService
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class HiveService {
  static const String _productBoxName = 'products';
  static const String _billBoxName = 'bills';
  static const String _customerBoxName = 'customers';
  static const String _userBoxName = 'users';
  static const String _settingsBoxName = 'settings';
  static const String _brandBoxName = 'brands';
  static const String _categoryBoxName = 'categories';
  static const String _shoppingListsBoxName =
      'shoppingLists'; // The lists themselves
  static const String _shoppingListBoxName = 'shoppingList'; // The items
  static const String _repairBoxName = 'repairs'; // Repair jobs
  static const String _expenseBoxName = 'expenses';
  static const String _expenseCategoryBoxName = 'expenseCategories';
  static const String _localPurchaseBoxName = 'localPurchases';
  static const String _syncQueueBoxName = SyncQueue.boxName;
  static const String _directoryPathKey = 'directoryPath';
  static const String _fieldConfigsKey = 'fieldConfigs';
  static const String _customerFieldConfigsKey =
      'customerFieldConfigs'; // New key for customer fields
  static const String _paymentMethodsKey = 'paymentMethods';

  /// Fallback payment methods used until the shop owner customizes them in
  /// Settings. The union of the old checkout and purchase lists.
  static const List<String> defaultPaymentMethods = [
    'Cash',
    'Online Pay',
    'Bank Transfer',
    'Cheque',
    'UPI / Digital',
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();
    final appPath = appDir.path;

    final storedPath = prefs.getString(_directoryPathKey) ?? appPath;
    Hive.init(storedPath);

    await Hive.openBox<Map>(_productBoxName);
    await Hive.openBox<Map>(_billBoxName);
    await Hive.openBox<Map>(_customerBoxName);
    await Hive.openBox<Map>(_userBoxName);
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox<Map>(_brandBoxName);
    await Hive.openBox<Map>(_categoryBoxName);
    await Hive.openBox<Map>(_shoppingListsBoxName);
    await Hive.openBox<Map>(_shoppingListBoxName);
    await Hive.openBox<Map>(_repairBoxName);
    await Hive.openBox<Map>(_expenseBoxName);
    await Hive.openBox<Map>(_expenseCategoryBoxName);
    await Hive.openBox<Map>(_localPurchaseBoxName);
    await Hive.openBox<Map>(_syncQueueBoxName);

    // Enqueue local settings changes so all devices share settings.
    _watchSettingsForSync();

    // Initialize default brands if brands box is empty
    await _initializeDefaultBrands();
    // Initialize default categories if categories box is empty
    await _initializeDefaultCategories();
    // Initialize default expense categories if empty
    await _initializeDefaultExpenseCategories();
    // Seed sample products/services for a computer repair & accessories shop
    await _initializeSampleData();
  }

  /// Seeds a set of sample products and services tailored to a computer
  /// repair & accessories shop. Runs once (guarded by a settings flag) so
  /// user deletions are not undone on the next launch.
  Future<void> _initializeSampleData() async {
    final settingsBox = await getSettingsBox();
    final alreadySeeded =
        settingsBox.get('sampleDataSeeded', defaultValue: false) as bool;
    if (alreadySeeded) return;

    final now = DateTime.now();

    bool nameExists(Box<Map> box, String name) => box.values.any(
      (m) =>
          (Map<String, dynamic>.from(m)['name'] as String?)?.toLowerCase() ==
          name.toLowerCase(),
    );

    // Ensure shop-specific categories exist (so they appear in dropdowns too).
    const sampleCategoryNames = [
      'Laptops',
      'Accessories',
      'Components',
      'Networking',
      'Repair Services',
    ];
    for (final name in sampleCategoryNames) {
      if (!nameExists(_categoryBox, name)) {
        final c = Category(
          id: 'cat_${name.hashCode}',
          name: name,
          imageUrl: null,
          createdAt: now,
          updatedAt: now,
        );
        await _categoryBox.put(c.id, c.toMap());
      }
    }

    // Ensure shop-specific brands exist.
    const sampleBrandNames = [
      'HP',
      'Dell',
      'Lenovo',
      'Logitech',
      'Kingston',
      'TP-Link',
      'Redragon',
      'Generic',
    ];
    for (final name in sampleBrandNames) {
      if (!nameExists(_brandBox, name)) {
        final b = Brand(
          id: 'brand_${name.hashCode}',
          name: name,
          createdAt: now,
          updatedAt: now,
        );
        await _brandBox.put(b.id, b.toMap());
      }
    }

    // Sample products (with stock).
    final products = <Product>[
      Product(
        id: 'seed_p_1',
        name: 'HP Pavilion 15 Laptop',
        price: 145000,
        stock: 6,
        category: 'Laptops',
        brand: 'HP',
        condition: 'New',
        purchasePrice: 130000,
        description: 'Core i5 12th Gen, 8GB RAM, 512GB SSD, 15.6" FHD display.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_2',
        name: 'Dell Inspiron 15 3520',
        price: 135000,
        stock: 5,
        category: 'Laptops',
        brand: 'Dell',
        condition: 'New',
        purchasePrice: 120000,
        description: 'Core i5, 8GB RAM, 256GB SSD, Windows 11.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_3',
        name: 'Lenovo ThinkPad E14',
        price: 95000,
        stock: 3,
        category: 'Laptops',
        brand: 'Lenovo',
        condition: 'Used',
        purchasePrice: 80000,
        description: 'Business laptop, Core i5 8th Gen, 8GB RAM, 256GB SSD.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_4',
        name: 'Logitech M170 Wireless Mouse',
        price: 1500,
        stock: 40,
        category: 'Accessories',
        brand: 'Logitech',
        condition: 'New',
        purchasePrice: 1000,
        description: 'Compact wireless mouse with USB receiver.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_5',
        name: 'Redragon Mechanical Keyboard',
        price: 6500,
        stock: 15,
        category: 'Accessories',
        brand: 'Redragon',
        condition: 'New',
        purchasePrice: 4800,
        description: 'RGB backlit mechanical gaming keyboard, blue switches.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_6',
        name: 'USB-C Hub 6-in-1',
        price: 3500,
        stock: 20,
        category: 'Accessories',
        brand: 'Generic',
        condition: 'New',
        purchasePrice: 2200,
        description: 'HDMI, USB 3.0, SD card and USB-C power delivery hub.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_7',
        name: 'Laptop Bag 15.6"',
        price: 2500,
        stock: 25,
        category: 'Accessories',
        brand: 'Generic',
        condition: 'New',
        purchasePrice: 1500,
        description: 'Water-resistant padded laptop backpack.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_8',
        name: 'HDMI Cable 2m',
        price: 800,
        stock: 50,
        category: 'Accessories',
        brand: 'Generic',
        condition: 'New',
        purchasePrice: 400,
        description: 'High-speed 4K HDMI 2.0 cable, 2 meters.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_9',
        name: 'Logitech C270 1080p Webcam',
        price: 4500,
        stock: 12,
        category: 'Accessories',
        brand: 'Logitech',
        condition: 'New',
        purchasePrice: 3200,
        description: 'HD webcam with built-in microphone.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_10',
        name: 'Kingston 8GB DDR4 RAM',
        price: 5500,
        stock: 18,
        category: 'Components',
        brand: 'Kingston',
        condition: 'New',
        purchasePrice: 4200,
        description: '8GB DDR4 3200MHz laptop/desktop memory module.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_11',
        name: 'Kingston 480GB SSD',
        price: 9000,
        stock: 14,
        category: 'Components',
        brand: 'Kingston',
        condition: 'New',
        purchasePrice: 7000,
        description: '2.5" SATA solid state drive, 480GB.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_12',
        name: 'Universal Laptop Charger 65W',
        price: 3000,
        stock: 22,
        category: 'Components',
        brand: 'Generic',
        condition: 'New',
        purchasePrice: 1800,
        description: 'Universal 65W adapter with multiple tips.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_13',
        name: 'TP-Link AC1200 WiFi Router',
        price: 7500,
        stock: 10,
        category: 'Networking',
        brand: 'TP-Link',
        condition: 'New',
        purchasePrice: 6000,
        description: 'Dual-band wireless router, up to 1200 Mbps.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_14',
        name: 'Kingston 64GB USB Flash Drive',
        price: 1200,
        stock: 60,
        category: 'Accessories',
        brand: 'Kingston',
        condition: 'New',
        purchasePrice: 800,
        description: 'USB 3.2 flash drive, 64GB.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_p_15',
        name: 'External HDD 1TB',
        price: 12000,
        stock: 8,
        category: 'Components',
        brand: 'Generic',
        condition: 'New',
        purchasePrice: 9500,
        description: 'Portable USB 3.0 external hard drive, 1TB.',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final p in products) {
      if (_productBox.get(p.id) == null) {
        await _productBox.put(p.id, p.toMap());
      }
    }

    // Sample services (no stock / brand / condition).
    final services = <Product>[
      Product(
        id: 'seed_s_1',
        name: 'Laptop Screen Replacement',
        price: 6500,
        isService: true,
        category: 'Repair Services',
        description: 'Replace cracked or faulty laptop display (panel extra).',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_2',
        name: 'Virus & Malware Removal',
        price: 2000,
        isService: true,
        category: 'Repair Services',
        description: 'Full malware scan, removal and system cleanup.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_3',
        name: 'Windows Installation',
        price: 1500,
        isService: true,
        category: 'Repair Services',
        description: 'Fresh Windows install with drivers and updates.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_4',
        name: 'Data Recovery',
        price: 5000,
        isService: true,
        category: 'Repair Services',
        description: 'Recover data from failing drives (subject to damage).',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_5',
        name: 'Hardware Diagnostics',
        price: 1000,
        isService: true,
        category: 'Repair Services',
        description: 'Full hardware checkup and fault diagnosis.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_6',
        name: 'Laptop Keyboard Replacement',
        price: 3500,
        isService: true,
        category: 'Repair Services',
        description: 'Replace damaged laptop keyboard (part extra).',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_7',
        name: 'Battery Replacement',
        price: 4000,
        isService: true,
        category: 'Repair Services',
        description: 'Replace worn-out laptop battery (battery extra).',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_8',
        name: 'Liquid Damage Repair',
        price: 8000,
        isService: true,
        category: 'Repair Services',
        description: 'Board cleaning and repair after liquid spills.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_9',
        name: 'Software Installation',
        price: 800,
        isService: true,
        category: 'Repair Services',
        description: 'Install and configure software packages.',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: 'seed_s_10',
        name: 'Full PC Tune-up & Cleaning',
        price: 2500,
        isService: true,
        category: 'Repair Services',
        description: 'Internal dust cleaning, thermal paste and optimization.',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    for (final s in services) {
      if (_productBox.get(s.id) == null) {
        await _productBox.put(s.id, s.toMap());
      }
    }

    // ---- Sample receipts/bills (related to products & customers) ----
    final lookup = {
      for (final p in [...products, ...services]) p.id: p,
    };

    Bill buildBill({
      required String id,
      required List<MapEntry<String, int>> lines,
      String? customerId,
      String? customerName,
      String? paymentMethod,
      double discount = 0,
      required double paidAmount,
      required DateTime dateTime,
    }) {
      final items = [for (final e in lines) lookup[e.key]!];
      final quantities = {for (final e in lines) e.key: e.value};
      final total = lines.fold<double>(
        0,
        (sum, e) => sum + lookup[e.key]!.price * e.value,
      );
      final fullyPaid = paidAmount >= (total - discount) - 0.01;
      return Bill(
        id: id,
        dateTime: dateTime,
        items: items,
        quantities: quantities,
        totalAmount: total,
        customerId: customerId,
        customerName: customerName,
        status: fullyPaid ? 'Paid' : 'Pending',
        paymentMethod: paymentMethod,
        discount: discount,
        paidAmount: paidAmount,
      );
    }

    final bills = <Bill>[
      buildBill(
        id: 'seed_b_1',
        customerId: 'seed_c_1',
        customerName: 'Ali Khan',
        paymentMethod: 'Cash',
        dateTime: now.subtract(const Duration(days: 2)),
        lines: const [MapEntry('seed_p_1', 1), MapEntry('seed_p_4', 1)],
        paidAmount: 146500, // fully paid
      ),
      buildBill(
        id: 'seed_b_2',
        customerId: 'seed_c_2',
        customerName: 'Sara Ahmed',
        paymentMethod: 'Card',
        dateTime: now.subtract(const Duration(days: 5)),
        lines: const [
          MapEntry('seed_p_2', 1),
          MapEntry('seed_p_7', 1),
          MapEntry('seed_p_8', 2),
        ],
        paidAmount: 100000, // partial (total 139100)
      ),
      buildBill(
        id: 'seed_b_3',
        customerId: 'seed_c_3',
        customerName: 'Bilal Hussain',
        paymentMethod: 'Cash',
        dateTime: now.subtract(const Duration(days: 1)),
        lines: const [
          MapEntry('seed_p_11', 1),
          MapEntry('seed_p_10', 2),
          MapEntry('seed_s_3', 1),
        ],
        paidAmount: 21500, // fully paid
      ),
      buildBill(
        id: 'seed_b_4',
        customerName: 'Walk-in Customer',
        paymentMethod: 'Cash',
        dateTime: now.subtract(const Duration(days: 7)),
        lines: const [MapEntry('seed_p_4', 2), MapEntry('seed_p_14', 3)],
        paidAmount: 6600, // fully paid
      ),
      buildBill(
        id: 'seed_b_5',
        customerId: 'seed_c_4',
        customerName: 'Ayesha Malik',
        paymentMethod: 'Card',
        dateTime: now.subtract(const Duration(days: 3)),
        lines: const [MapEntry('seed_s_1', 1), MapEntry('seed_s_7', 1)],
        paidAmount: 10500, // fully paid
      ),
      buildBill(
        id: 'seed_b_6',
        customerId: 'seed_c_1',
        customerName: 'Ali Khan',
        paymentMethod: 'Cash',
        dateTime: now.subtract(const Duration(days: 10)),
        lines: const [MapEntry('seed_p_9', 1), MapEntry('seed_p_5', 1)],
        paidAmount: 5000, // partial (total 11000)
      ),
    ];
    for (final b in bills) {
      if (_billBox.get(b.id) == null) {
        await _billBox.put(b.id, b.toMap());
      }
    }

    // ---- Sample customers (aggregates derived from their bills) ----
    final customerInfo = <String, List<String>>{
      // id: [name, address, phone]
      'seed_c_1': ['Ali Khan', 'Gulshan, Karachi', '0300-1234567'],
      'seed_c_2': ['Sara Ahmed', 'DHA, Lahore', '0321-2345678'],
      'seed_c_3': ['Bilal Hussain', 'F-10, Islamabad', '0333-3456789'],
      'seed_c_4': ['Ayesha Malik', 'Cantt, Rawalpindi', '0345-4567890'],
    };
    for (final entry in customerInfo.entries) {
      final cid = entry.key;
      final custBills = bills.where((b) => b.customerId == cid).toList();
      final customer = Customer(
        id: cid,
        name: entry.value[0],
        address: entry.value[1],
        phoneNumber: entry.value[2],
        visitCount: custBills.length,
        billIds: custBills.map((b) => b.id).toList(),
        totalPaidAmount: custBills.fold<double>(0, (s, b) => s + b.paidAmount),
        totalPendingAmount: custBills.fold<double>(
          0,
          (s, b) => s + b.pendingAmount,
        ),
      );
      if (_customerBox.get(cid) == null) {
        await _customerBox.put(cid, customer.toMap());
      }
    }

    // ---- Sample expenses (related to seeded expense categories) ----
    final expenses = <Expense>[
      Expense(
        id: 'seed_e_1',
        amount: 25000,
        categoryId: 'rent',
        categoryName: 'Rent',
        date: now.subtract(const Duration(days: 15)),
        note: 'Shop monthly rent',
        createdAt: now,
      ),
      Expense(
        id: 'seed_e_2',
        amount: 6000,
        categoryId: 'utilities',
        categoryName: 'Utilities',
        date: now.subtract(const Duration(days: 10)),
        note: 'Electricity bill',
        createdAt: now,
      ),
      Expense(
        id: 'seed_e_3',
        amount: 30000,
        categoryId: 'salaries',
        categoryName: 'Salaries',
        date: now.subtract(const Duration(days: 5)),
        note: 'Technician salary',
        createdAt: now,
      ),
      Expense(
        id: 'seed_e_4',
        amount: 4500,
        categoryId: 'supplies',
        categoryName: 'Supplies',
        date: now.subtract(const Duration(days: 8)),
        note: 'Repair tools & spare parts',
        createdAt: now,
      ),
      Expense(
        id: 'seed_e_5',
        amount: 3000,
        categoryId: 'marketing',
        categoryName: 'Marketing',
        date: now.subtract(const Duration(days: 12)),
        note: 'Facebook ads',
        createdAt: now,
      ),
      Expense(
        id: 'seed_e_6',
        amount: 1500,
        categoryId: 'transport',
        categoryName: 'Transport',
        date: now.subtract(const Duration(days: 3)),
        note: 'Parts pickup fuel',
        createdAt: now,
      ),
    ];
    for (final e in expenses) {
      if (_expenseBox.get(e.id) == null) {
        await _expenseBox.put(e.id, e.toMap());
      }
    }

    await settingsBox.put('sampleDataSeeded', true);
  }

  Future<void> setDirectoryPath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    final oldPath = await directoryPath;

    if (oldPath == newPath) return;

    final oldHiveDir = Directory(oldPath);
    final newHiveDir = Directory(newPath);

    if (!await newHiveDir.exists()) {
      await newHiveDir.create(recursive: true);
    }

    await Hive.close();

    // Try to copy files from old directory to new directory
    try {
      if (await oldHiveDir.exists()) {
        for (var entity in oldHiveDir.listSync()) {
          if (entity is File) {
            final newFile = File(
              '${newHiveDir.path}/${entity.uri.pathSegments.last}',
            );
            try {
              await newFile.writeAsBytes(await entity.readAsBytes());
            } catch (e) {
              debugPrint('Error copying file ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      // If we can't access the old directory, just start fresh in the new one
      debugPrint('Cannot access old directory, starting fresh: $e');
    }

    Hive.init(newPath);
    await Hive.openBox<Map>(_productBoxName);
    await Hive.openBox<Map>(_billBoxName);
    await Hive.openBox<Map>(_customerBoxName);
    await Hive.openBox<Map>(_userBoxName);
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox<Map>(_brandBoxName);
    await Hive.openBox<Map>(_categoryBoxName);
    await Hive.openBox<Map>(_localPurchaseBoxName);

    await prefs.setString(_directoryPathKey, newPath);
  }

  Future<String> get directoryPath async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_directoryPathKey) ??
        (await getApplicationDocumentsDirectory()).path;
  }

  Future<Box> getSettingsBox() async {
    if (!Hive.isBoxOpen(_settingsBoxName)) {
      return await Hive.openBox(_settingsBoxName);
    }
    return Hive.box(_settingsBoxName);
  }

  static Box<Map> get _productBox => Hive.box<Map>(_productBoxName);
  static Box<Map> get _billBox => Hive.box<Map>(_billBoxName);
  static Box<Map> get _customerBox => Hive.box<Map>(_customerBoxName);
  static Box<Map> get _userBox => Hive.box<Map>(_userBoxName);
  static Box get _settingsBox => Hive.box(_settingsBoxName);
  static Box<Map> get _brandBox => Hive.box<Map>(_brandBoxName);
  static Box<Map> get _categoryBox => Hive.box<Map>(_categoryBoxName);
  static Box<Map> get _shoppingListsBox => Hive.box<Map>(_shoppingListsBoxName);
  static Box<Map> get _shoppingListBox => Hive.box<Map>(_shoppingListBoxName);
  static Box<Map> get _repairBox => Hive.box<Map>(_repairBoxName);
  static Box<Map> get _localPurchaseBox => Hive.box<Map>(_localPurchaseBoxName);
  static Box<Map> get _syncQueueBox => Hive.box<Map>(_syncQueueBoxName);

  // Product Field Configs
  Future<void> saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
    final settingsBox = await getSettingsBox();
    final fieldConfigsMap = fieldConfigs.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    await settingsBox.put(_fieldConfigsKey, fieldConfigsMap);
  }

  Future<Map<String, FieldConfig>> getFieldConfigs() async {
    final settingsBox = await getSettingsBox();
    final fieldConfigsMap = settingsBox.get(_fieldConfigsKey);
    if (fieldConfigsMap == null) {
      return {
        'name': FieldConfig.initial('name', WidgetType.textField),
        'price': FieldConfig.initial('price', WidgetType.textField),
        'imageFile': FieldConfig.initial('imageFile', WidgetType.imagePicker),
        'warranty': FieldConfig.initial('warranty', WidgetType.dropdown),
        'condition': FieldConfig.initial('condition', WidgetType.dropdown),
        'brand': FieldConfig.initial('brand', WidgetType.dropdown),
        'description': FieldConfig.initial('description', WidgetType.textField),
        'purchasePrice': FieldConfig.initial(
          'purchasePrice',
          WidgetType.textField,
        ),
        'stock': FieldConfig.initial('stock', WidgetType.textField),
        'isBackup': FieldConfig.initial('isBackup', WidgetType.checkbox),
      };
    }
    return (fieldConfigsMap as Map).map(
      (key, value) =>
          MapEntry(key, FieldConfig.fromMap(Map<String, dynamic>.from(value))),
    );
  }

  // Customer Field Configs
  Future<void> saveCustomerFieldConfigs(
    Map<String, FieldConfig> fieldConfigs,
  ) async {
    final settingsBox = await getSettingsBox();
    final fieldConfigsMap = fieldConfigs.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    await settingsBox.put(_customerFieldConfigsKey, fieldConfigsMap);
  }

  Future<Map<String, FieldConfig>> getCustomerFieldConfigs() async {
    final settingsBox = await getSettingsBox();
    final fieldConfigsMap = settingsBox.get(_customerFieldConfigsKey);
    if (fieldConfigsMap == null) {
      return {
        'name': FieldConfig.initial('name', WidgetType.textField),
        'address': FieldConfig.initial('address', WidgetType.textField),
        'phoneNumber': FieldConfig.initial('phoneNumber', WidgetType.textField),
        'paidAmount': FieldConfig.initial('paidAmount', WidgetType.textField),
        'paymentStatus': FieldConfig.initial(
          'paymentStatus',
          WidgetType.dropdown,
        ),
        'paymentMethod': FieldConfig.initial(
          'paymentMethod',
          WidgetType.dropdown,
        ),
        'discount': FieldConfig.initial('discount', WidgetType.textField),
      };
    }
    return (fieldConfigsMap as Map).map(
      (key, value) =>
          MapEntry(key, FieldConfig.fromMap(Map<String, dynamic>.from(value))),
    );
  }

  // Payment Methods (Settings → Bill Settings → Payment Methods)
  Future<List<String>> getPaymentMethods() async {
    final settingsBox = await getSettingsBox();
    final stored = settingsBox.get(_paymentMethodsKey);
    if (stored is List) {
      final methods = stored.map((e) => e.toString()).toList();
      if (methods.isNotEmpty) return methods;
    }
    return List<String>.from(defaultPaymentMethods);
  }

  Future<void> savePaymentMethods(List<String> methods) async {
    final settingsBox = await getSettingsBox();
    await settingsBox.put(_paymentMethodsKey, methods);
  }

  List<Product> getProducts() {
    return _productBox.values
        .map((e) => Product.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addProduct(Product product) async {
    await _productBox.put(product.id, product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _productBox.put(product.id, product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _productBox.delete(id);
  }

  List<Bill> getBills() {
    final List<Bill> bills = [];
    for (var value in _billBox.values) {
      try {
        final billMap = Map<String, dynamic>.from(value);
        billMap['customerId'] ??= null;
        billMap['paymentMethod'] ??= null;
        bills.add(Bill.fromMap(billMap));
      } catch (e) {
        debugPrint('Error deserializing bill: $e');
      }
    }
    return bills;
  }

  Future<void> saveBill(Bill bill) async {
    await _billBox.put(bill.id, bill.toMap());
  }

  List<Customer> getCustomers() {
    return _customerBox.values
        .map((e) => Customer.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }

  List<User> getUsers() {
    return _userBox.values
        .map((e) => User.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveUser(User user) async {
    await _userBox.put(user.id, user.toMap());
  }

  Future<void> updateUser(User user) async {
    await _userBox.put(user.id, user.toMap());
  }

  Future<void> deleteUser(String id) async {
    await _userBox.delete(id);
  }

  Future<void> clearAll() async {
    await _productBox.clear();
    await _billBox.clear();
    await _customerBox.clear();
    await _userBox.clear();
    await _settingsBox.clear();
  }

  Future<void> deleteBill(String id) async {
    await _billBox.delete(id);
  }

  // Brand Management Methods
  Future<void> _initializeDefaultBrands() async {
    if (_brandBox.isEmpty) {
      final defaultBrands = [
        'HP',
        'Dell',
        'Lenovo',
        'Asus',
        'Acer',
        'Apple',
        'MSI',
        'Samsung',
        'LG',
        'Sony',
      ];

      for (final brandName in defaultBrands) {
        final brand = Brand(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              brandName.hashCode.toString(),
          name: brandName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _brandBox.put(brand.id, brand.toMap());
      }
    }
  }

  Future<List<Brand>> getBrands() async {
    final brandMaps = _brandBox.values.toList();
    final allBrands =
        brandMaps
            .map((map) => Brand.fromMap(Map<String, dynamic>.from(map)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    // Deduplicate by name (keep the first occurrence)
    final seenNames = <String>{};
    final uniqueBrands = <Brand>[];
    for (final brand in allBrands) {
      if (seenNames.add(brand.name.toLowerCase())) {
        uniqueBrands.add(brand);
      }
    }
    return uniqueBrands;
  }

  Future<void> addBrand(Brand brand) async {
    // Check for duplicate name (case-insensitive)
    final existingBrands = await getBrands();
    final duplicate = existingBrands.any(
      (b) => b.name.toLowerCase() == brand.name.toLowerCase(),
    );
    if (!duplicate) {
      await _brandBox.put(brand.id, brand.toMap());
    }
  }

  Future<void> updateBrand(Brand brand) async {
    await _brandBox.put(brand.id, brand.toMap());
  }

  Future<void> deleteBrand(String id) async {
    await _brandBox.delete(id);
  }

  // Category Management Methods
  Future<void> _initializeDefaultCategories() async {
    if (_categoryBox.isEmpty) {
      final defaultCategories = [
        'Electronics',
        'Clothing',
        'Food & Beverages',
        'Home & Garden',
        'Sports & Outdoors',
        'Books',
        'Toys & Games',
        'Health & Beauty',
        'Automotive',
        'Office Supplies',
      ];

      for (final categoryName in defaultCategories) {
        final category = Category(
          id: categoryName.hashCode.toString(),
          name: categoryName,
          imageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _categoryBox.put(category.id, category.toMap());
      }
    }
  }

  Future<List<Category>> getCategories() async {
    final categoryMaps = _categoryBox.values.toList();
    final allCategories =
        categoryMaps
            .map((map) => Category.fromMap(Map<String, dynamic>.from(map)))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    // Deduplicate by name (keep the first occurrence)
    final seenNames = <String>{};
    final uniqueCategories = <Category>[];
    for (final category in allCategories) {
      if (seenNames.add(category.name.toLowerCase())) {
        uniqueCategories.add(category);
      }
    }
    return uniqueCategories;
  }

  Future<void> addCategory(Category category) async {
    // Check for duplicate name (case-insensitive)
    final existingCategories = await getCategories();
    final duplicate = existingCategories.any(
      (c) => c.name.toLowerCase() == category.name.toLowerCase(),
    );
    if (!duplicate) {
      await _categoryBox.put(category.id, category.toMap());
    }
  }

  Future<void> updateCategory(Category category) async {
    await _categoryBox.put(category.id, category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  // Expense Box Getters
  Box<Map> get _expenseBox => Hive.box<Map>(_expenseBoxName);
  Box<Map> get _expenseCategoryBox => Hive.box<Map>(_expenseCategoryBoxName);

  // Initialize default expense categories
  Future<void> _initializeDefaultExpenseCategories() async {
    if (_expenseCategoryBox.isEmpty) {
      final defaultCategories = ExpenseCategory.defaultCategories;
      for (final category in defaultCategories) {
        await _expenseCategoryBox.put(category.id, category.toMap());
      }
    }
  }

  // Expense Category CRUD Methods
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    final categoryMaps = _expenseCategoryBox.values.toList();
    return categoryMaps
        .map((map) => ExpenseCategory.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> addExpenseCategory(ExpenseCategory category) async {
    final existingCategories = await getExpenseCategories();
    final duplicate = existingCategories.any(
      (c) => c.name.toLowerCase() == category.name.toLowerCase(),
    );
    if (!duplicate) {
      await _expenseCategoryBox.put(category.id, category.toMap());
    }
  }

  Future<void> updateExpenseCategory(ExpenseCategory category) async {
    await _expenseCategoryBox.put(category.id, category.toMap());
  }

  Future<void> deleteExpenseCategory(String id) async {
    // Don't delete default categories
    final category = _expenseCategoryBox.get(id);
    if (category != null) {
      final cat = ExpenseCategory.fromMap(Map<String, dynamic>.from(category));
      if (!cat.isDefault) {
        await _expenseCategoryBox.delete(id);
      }
    }
  }

  // Expense CRUD Methods
  Future<List<Expense>> getExpenses() async {
    final expenseMaps = _expenseBox.values.toList();
    return expenseMaps
        .map((map) => Expense.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final allExpenses = await getExpenses();
    return allExpenses.where((expense) {
      return expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    final allExpenses = await getExpenses();
    return allExpenses.where((e) => e.categoryId == categoryId).toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    await _expenseBox.put(updated.id, updated.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  // Shopping Lists (the lists themselves) Management Methods
  Future<List<ShoppingList>> getShoppingLists() async {
    final listsMap = _shoppingListsBox.values.toList();
    return listsMap
        .map((map) => ShoppingList.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> createShoppingList(ShoppingList list) async {
    await _shoppingListsBox.put(list.id, list.toMap());
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    await _shoppingListsBox.put(list.id, list.toMap());
  }

  Future<void> deleteShoppingList(String listId) async {
    // Delete the list
    await _shoppingListsBox.delete(listId);

    // Also delete all items in this list
    final items = await getShoppingListItems(listId);
    for (final item in items) {
      await deleteShoppingListItem(item.id);
    }
  }

  Future<void> duplicateShoppingList(String listId, String newListName) async {
    final items = await getShoppingListItems(listId);
    final now = DateTime.now();

    // Create new list
    final newList = ShoppingList(
      id: now.millisecondsSinceEpoch.toString(),
      name: newListName,
      createdAt: now,
      updatedAt: now,
    );
    await createShoppingList(newList);

    // Copy all items to new list
    for (final item in items) {
      final newItem = item.copyWith(
        id: '${now.millisecondsSinceEpoch}_${item.id}',
        listId: newList.id,
        isShopped: false, // Reset shopped status
        createdAt: now,
        updatedAt: now,
      );
      await addToShoppingList(newItem);
    }
  }

  // Shopping List Items Management Methods
  Future<List<ShoppingListItem>> getShoppingListItems(String listId) async {
    final shoppingListMaps = _shoppingListBox.values.toList();
    final allItems =
        shoppingListMaps
            .map(
              (map) => ShoppingListItem.fromMap(Map<String, dynamic>.from(map)),
            )
            .toList();

    // Filter by listId
    return allItems.where((item) => item.listId == listId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Keep old method for backward compatibility
  Future<List<ShoppingListItem>> getShoppingList() async {
    final shoppingListMaps = _shoppingListBox.values.toList();
    return shoppingListMaps
        .map((map) => ShoppingListItem.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addToShoppingList(ShoppingListItem item) async {
    await _shoppingListBox.put(item.id, item.toMap());
  }

  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    await _shoppingListBox.put(item.id, item.toMap());
  }

  Future<void> deleteShoppingListItem(String id) async {
    await _shoppingListBox.delete(id);
  }

  Future<void> markItemsAsShopped(List<String> itemIds) async {
    for (final id in itemIds) {
      final itemMap = _shoppingListBox.get(id);
      if (itemMap != null) {
        final item = ShoppingListItem.fromMap(
          Map<String, dynamic>.from(itemMap),
        );
        final updatedItem = item.copyWith(
          isShopped: true,
          updatedAt: DateTime.now(),
        );
        await _shoppingListBox.put(id, updatedItem.toMap());
      }
    }
  }

  Future<void> clearShoppedItems([String? listId]) async {
    final items =
        listId != null
            ? await getShoppingListItems(listId)
            : await getShoppingList();
    for (final item in items) {
      if (item.isShopped) {
        await _shoppingListBox.delete(item.id);
      }
    }
  }

  // Repair Jobs Management Methods
  Future<List<Repair>> getRepairs() async {
    final maps = _repairBox.values.toList();
    return maps
        .map((map) => Repair.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addRepair(Repair repair) async {
    await _repairBox.put(repair.id, repair.toMap());
  }

  Future<void> updateRepair(Repair repair) async {
    await _repairBox.put(repair.id, repair.toMap());
  }

  Future<void> deleteRepair(String id) async {
    await _repairBox.delete(id);
  }

  // Local Purchase Agreement Methods
  Future<List<LocalPurchaseAgreement>> getLocalPurchases() async {
    final maps = _localPurchaseBox.values.toList();
    return maps
        .map(
          (map) =>
              LocalPurchaseAgreement.fromMap(Map<String, dynamic>.from(map)),
        )
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> saveLocalPurchase(LocalPurchaseAgreement agreement) async {
    await _localPurchaseBox.put(agreement.id, agreement.toMap());
  }

  Future<void> deleteLocalPurchase(String id) async {
    await _localPurchaseBox.delete(id);
  }

  Future<void> close() async {
    await Hive.close();
  }

  // ---- Sync helpers (remote apply + local enqueue) ----

  /// Broadcast stream fired whenever a REMOTE change (made on another
  /// device, delivered via Firestore realtime) is applied into local Hive.
  /// The event value is the table name. UI providers listen to this to
  /// reload their in-memory lists, so open screens update live.
  final StreamController<String> _remoteDataChanges =
      StreamController<String>.broadcast();

  Stream<String> get remoteDataChanges => _remoteDataChanges.stream;

  /// Resolves the Hive box for a synced table; null when not synced.
  Box<Map>? _boxForTable(String table) {
    switch (table) {
      case 'products':
        return _productBox;
      case 'customers':
        return _customerBox;
      case 'bills':
        return _billBox;
      case 'brands':
        return _brandBox;
      case 'categories':
        return _categoryBox;
      case 'expenses':
        return _expenseBox;
      case 'repairs':
        return _repairBox;
      case 'localPurchases':
        return _localPurchaseBox;
      default:
        return null;
    }
  }

  // ---- Settings sync ----

  /// Keys of the settings box that are shared across devices. Everything
  /// else (per-device push flags, seeding markers, etc.) stays local.
  static const Set<String> _settingsSyncKeys = {
    'settings',
    _fieldConfigsKey,
    _customerFieldConfigsKey,
    _paymentMethodsKey,
  };

  /// Guard so settings applied from Firestore aren't echoed back up.
  /// Static because several HiveService instances can exist app-wide.
  static bool _applyingRemoteSettings = false;

  /// Fields inside the shared "settings" map that are device-specific
  /// (local file paths) and must not travel between devices.
  static const Set<String> _deviceLocalSettingFields = {
    'directoryPath',
    'bannerImagePaths',
  };

  /// Copies a settings value with device-local fields removed so they
  /// never overwrite another device's local paths.
  dynamic _stripDeviceLocalFields(dynamic value) {
    if (value is Map) {
      final copy = Map<String, dynamic>.from(value);
      copy.removeWhere(
        (k, _) => _deviceLocalSettingFields.contains(k.toString()),
      );
      return copy;
    }
    return value;
  }

  /// Set once the settings write-watcher is attached (also static so
  /// multiple HiveService instances don't attach duplicate listeners).
  static bool _settingsWatchAttached = false;

  /// Watches local settings writes and enqueues them so every device
  /// shares the same settings (API keys, print config, field layouts...).
  void _watchSettingsForSync() {
    if (_settingsWatchAttached || !Hive.isBoxOpen(_settingsBoxName)) return;
    _settingsWatchAttached = true;
    Hive.box(_settingsBoxName).watch().listen((event) {
      if (_applyingRemoteSettings) return;
      final key = event.key?.toString() ?? '';
      if (event.deleted || !_settingsSyncKeys.contains(key)) return;
      final value = Hive.box(_settingsBoxName).get(key);
      if (value == null) return;
      enqueueUpsert('settings', {
        'id': key,
        'value': _stripDeviceLocalFields(value),
      });
    });
  }

  /// Wraps the shared settings keys as {id, value} records so the sync
  /// machinery can treat the settings box like any other table.
  Future<List<Map<String, dynamic>>> _localSettingsRecords() async {
    final box = await getSettingsBox();
    return [
      for (final key in _settingsSyncKeys)
        if (box.get(key) != null)
          {'id': key, 'value': _stripDeviceLocalFields(box.get(key))},
    ];
  }

  /// Clears the local Hive boxes of the given synced tables (Settings →
  /// Clear Data).
  Future<void> clearTables(Set<String> tables) async {
    for (final table in tables) {
      final box = _boxForTable(table);
      if (box != null) await box.clear();
    }
  }

  /// Removes queued sync ops for the given tables so pending writes can't
  /// resurrect data that was just cleared.
  Future<void> purgeQueueForTables(Set<String> tables) async {
    final keys = _syncQueueBox.keys.toList();
    for (final key in keys) {
      final map = _syncQueueBox.get(key);
      if (map == null) continue;
      final table = (map['table'] ?? '').toString();
      if (tables.contains(table)) await _syncQueueBox.delete(key);
    }
  }

  /// Fires the remote-change signal for a table so open screens reload
  /// after a local clear (providers re-read the now-empty boxes).
  void notifyDataCleared(String table) => _remoteDataChanges.add(table);

  Future<void> enqueueUpsert(String table, Map<String, dynamic> payload) async {
    final op = SyncOp(
      id: const Uuid().v4(),
      table: table,
      type: SyncOpType.upsert,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _syncQueueBox.put(op.id, op.toMap());
  }

  Future<void> enqueueDelete(String table, String id) async {
    final op = SyncOp(
      id: const Uuid().v4(),
      table: table,
      type: SyncOpType.delete,
      payload: {'id': id},
      createdAt: DateTime.now(),
    );
    await _syncQueueBox.put(op.id, op.toMap());
  }

  /// Returns every local record of a synced table (used by the one-time
  /// initial cloud push so old local data gets shared).
  Future<List<Map<String, dynamic>>> getLocalRecords(String table) async {
    if (table == 'settings') return _localSettingsRecords();
    final box = _boxForTable(table);
    if (box == null) return const [];
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Apply a Firestore realtime upsert into local Hive.
  /// This expects the remote doc to use the same keys used by local `toMap()`.
  /// Fires [remoteDataChanges] so the UI reloads live.
  Future<void> applyRemoteUpsert({
    required String table,
    required Map<String, dynamic> record,
  }) async {
    if (table == 'settings') {
      // Settings docs are wrapped as {id: key, value: ...}.
      final key = (record['id'] ?? '').toString();
      if (!_settingsSyncKeys.contains(key)) return;
      var value = record['value'];
      if (value == null) return;
      if (key == 'settings' && value is Map) {
        // Keep this device's own local fields (file paths) — everything
        // else comes from the cloud.
        final local = Hive.box(_settingsBoxName).get(key);
        if (local is Map) {
          final merged = Map<String, dynamic>.from(value);
          for (final field in _deviceLocalSettingFields) {
            if (local.containsKey(field)) merged[field] = local[field];
          }
          value = merged;
        }
      }
      final box = await getSettingsBox();
      _applyingRemoteSettings = true;
      try {
        await box.put(key, value);
      } finally {
        _applyingRemoteSettings = false;
      }
      _remoteDataChanges.add(table);
      return;
    }

    final id = (record['id'] ?? '').toString();
    if (id.isEmpty) return;

    final box = _boxForTable(table);
    if (box == null) return;
    await box.put(id, Map<String, dynamic>.from(record));
    _remoteDataChanges.add(table);
  }

  /// Apply a Firestore realtime delete into local Hive.
  /// Fires [remoteDataChanges] so the UI reloads live.
  Future<void> applyRemoteDelete({
    required String table,
    required String id,
  }) async {
    if (id.isEmpty) return;
    // Settings keys are never deleted remotely — only overwritten.
    if (table == 'settings') return;
    final box = _boxForTable(table);
    if (box == null) return;
    await box.delete(id);
    _remoteDataChanges.add(table);
  }
}

class DatabaseService {
  final HiveService _hiveService;

  DatabaseService() : _hiveService = HiveService();

  Future<void> initialize() async {
    await _hiveService.init();
  }

  Future<List<Product>> getProducts() async {
    return _hiveService.getProducts();
  }

  Future<void> addProduct(Product product) async {
    await _hiveService.addProduct(product);
    await _hiveService.enqueueUpsert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _hiveService.updateProduct(product);
    await _hiveService.enqueueUpsert('products', product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _hiveService.deleteProduct(id);
    await _hiveService.enqueueDelete('products', id);
  }

  Future<void> saveBill(Bill bill) async {
    await _hiveService.saveBill(bill);
    await _hiveService.enqueueUpsert('bills', bill.toMap());
  }

  Future<List<Bill>> getBills() async {
    return _hiveService.getBills();
  }

  Future<List<Customer>> getCustomers() async {
    return _hiveService.getCustomers();
  }

  Future<void> saveCustomer(Customer customer) async {
    await _hiveService.saveCustomer(customer);
    await _hiveService.enqueueUpsert('customers', customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    await _hiveService.updateCustomer(customer);
    await _hiveService.enqueueUpsert('customers', customer.toMap());
  }

  Future<void> deleteCustomer(String id) async {
    await _hiveService.deleteCustomer(id);
    await _hiveService.enqueueDelete('customers', id);
  }

  Future<List<User>> getUsers() async {
    return _hiveService.getUsers();
  }

  Future<void> saveUser(User user) async {
    await _hiveService.saveUser(user);
  }

  Future<void> updateUser(User user) async {
    await _hiveService.updateUser(user);
  }

  Future<void> deleteUser(String id) async {
    await _hiveService.deleteUser(id);
  }

  Future<void> clearAllData() async {
    await _hiveService.clearAll();
  }

  /// Data groups offered in Settings → Clear Data, mapped to the synced
  /// tables each group covers (products includes brands and categories).
  static const Map<String, List<String>> dataGroupTables = {
    'products': ['products', 'brands', 'categories'],
    'bills': ['bills'],
    'customers': ['customers'],
    'expenses': ['expenses'],
    'repairs': ['repairs'],
    'purchases': ['localPurchases'],
  };

  /// Permanently deletes the selected data groups from BOTH this device
  /// (Hive) and the cloud (Firestore), so realtime sync drops them on
  /// every device. Queued-but-not-yet-synced writes are also discarded.
  Future<void> clearDataGroups(Set<String> groups) async {
    final tables = <String>{
      for (final g in groups) ...(dataGroupTables[g] ?? const <String>[]),
    };
    if (tables.isEmpty) return;

    // Cloud first: every device's realtime listener receives the removals
    // and drops its local copy automatically.
    for (final table in tables) {
      try {
        await FirebaseService.instance.clearCollection(table);
      } catch (e) {
        debugPrint('Cloud clear failed for "$table": $e');
      }
    }

    await _hiveService.clearTables(tables);
    await _hiveService.purgeQueueForTables(tables);
    for (final table in tables) {
      _hiveService.notifyDataCleared(table);
    }
  }

  Future<void> setNewDirectory(String newPath) async {
    await _hiveService.setDirectoryPath(newPath);
  }

  Future<String> getCurrentHivePath() async {
    return await _hiveService.directoryPath;
  }

  Future<void> deleteBill(String id) async {
    await _hiveService.deleteBill(id);
    await _hiveService.enqueueDelete('bills', id);
  }

  Future<void> close() async {
    await _hiveService.close();
  }

  Future<void> saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
    await _hiveService.saveFieldConfigs(fieldConfigs);
  }

  Future<Map<String, FieldConfig>> getFieldConfigs() async {
    return await _hiveService.getFieldConfigs();
  }

  Future<void> saveCustomerFieldConfigs(
    Map<String, FieldConfig> fieldConfigs,
  ) async {
    await _hiveService.saveCustomerFieldConfigs(fieldConfigs);
  }

  Future<Map<String, FieldConfig>> getCustomerFieldConfigs() async {
    return await _hiveService.getCustomerFieldConfigs();
  }

  // Payment Methods
  Future<List<String>> getPaymentMethods() async {
    return await _hiveService.getPaymentMethods();
  }

  Future<void> savePaymentMethods(List<String> methods) async {
    await _hiveService.savePaymentMethods(methods);
  }

  // Brand Management Methods
  Future<List<Brand>> getBrands() async {
    return await _hiveService.getBrands();
  }

  Future<void> addBrand(Brand brand) async {
    await _hiveService.addBrand(brand);
    await _hiveService.enqueueUpsert('brands', brand.toMap());
  }

  Future<void> updateBrand(Brand brand) async {
    await _hiveService.updateBrand(brand);
    await _hiveService.enqueueUpsert('brands', brand.toMap());
  }

  Future<void> deleteBrand(String id) async {
    await _hiveService.deleteBrand(id);
    await _hiveService.enqueueDelete('brands', id);
  }

  // Category Management Methods
  Future<List<Category>> getCategories() async {
    return await _hiveService.getCategories();
  }

  Future<void> addCategory(Category category) async {
    await _hiveService.addCategory(category);
    await _hiveService.enqueueUpsert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    await _hiveService.updateCategory(category);
    await _hiveService.enqueueUpsert('categories', category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _hiveService.deleteCategory(id);
    await _hiveService.enqueueDelete('categories', id);
  }

  // Shopping Lists Management Methods
  Future<List<ShoppingList>> getShoppingLists() async {
    return await _hiveService.getShoppingLists();
  }

  Future<void> createShoppingList(ShoppingList list) async {
    await _hiveService.createShoppingList(list);
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    await _hiveService.updateShoppingList(list);
  }

  Future<void> deleteShoppingList(String listId) async {
    await _hiveService.deleteShoppingList(listId);
  }

  Future<void> duplicateShoppingList(String listId, String newListName) async {
    await _hiveService.duplicateShoppingList(listId, newListName);
  }

  // Shopping List Items Management Methods
  Future<List<ShoppingListItem>> getShoppingListItems(String listId) async {
    return await _hiveService.getShoppingListItems(listId);
  }

  Future<List<ShoppingListItem>> getShoppingList() async {
    return await _hiveService.getShoppingList();
  }

  Future<void> addToShoppingList(ShoppingListItem item) async {
    await _hiveService.addToShoppingList(item);
  }

  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    await _hiveService.updateShoppingListItem(item);
  }

  Future<void> deleteShoppingListItem(String id) async {
    await _hiveService.deleteShoppingListItem(id);
  }

  Future<void> markItemsAsShopped(List<String> itemIds) async {
    await _hiveService.markItemsAsShopped(itemIds);
  }

  Future<void> clearShoppedItems([String? listId]) async {
    await _hiveService.clearShoppedItems(listId);
  }

  // Repair Jobs Management Methods
  Future<List<Repair>> getRepairs() async {
    return await _hiveService.getRepairs();
  }

  Future<void> addRepair(Repair repair) async {
    await _hiveService.addRepair(repair);
    await _hiveService.enqueueUpsert('repairs', repair.toMap());
  }

  Future<void> updateRepair(Repair repair) async {
    await _hiveService.updateRepair(repair);
    await _hiveService.enqueueUpsert('repairs', repair.toMap());
  }

  Future<void> deleteRepair(String id) async {
    await _hiveService.deleteRepair(id);
    await _hiveService.enqueueDelete('repairs', id);
  }

  // Local Purchase Agreement Management Methods
  Future<List<LocalPurchaseAgreement>> getLocalPurchases() async {
    return await _hiveService.getLocalPurchases();
  }

  Future<void> saveLocalPurchase(LocalPurchaseAgreement agreement) async {
    await _hiveService.saveLocalPurchase(agreement);
    await _hiveService.enqueueUpsert('localPurchases', agreement.toMap());
  }

  Future<void> deleteLocalPurchase(String id) async {
    await _hiveService.deleteLocalPurchase(id);
    await _hiveService.enqueueDelete('localPurchases', id);
  }

  // Expense Management Methods
  Future<List<Expense>> getExpenses() async {
    return await _hiveService.getExpenses();
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return await _hiveService.getExpensesByDateRange(start, end);
  }

  Future<List<Expense>> getExpensesByCategory(String categoryId) async {
    return await _hiveService.getExpensesByCategory(categoryId);
  }

  Future<void> addExpense(Expense expense) async {
    await _hiveService.addExpense(expense);
    await _hiveService.enqueueUpsert('expenses', expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _hiveService.updateExpense(expense);
    await _hiveService.enqueueUpsert('expenses', expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _hiveService.deleteExpense(id);
    await _hiveService.enqueueDelete('expenses', id);
  }

  // Expense Category Management Methods
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    return await _hiveService.getExpenseCategories();
  }

  Future<void> addExpenseCategory(ExpenseCategory category) async {
    await _hiveService.addExpenseCategory(category);
  }

  Future<void> updateExpenseCategory(ExpenseCategory category) async {
    await _hiveService.updateExpenseCategory(category);
  }

  Future<void> deleteExpenseCategory(String id) async {
    await _hiveService.deleteExpenseCategory(id);
  }
}

// class HiveService {
//   static const String _productBoxName = 'products';
//   static const String _billBoxName = 'bills';
//   static const String _customerBoxName = 'customers';
//   static const String _userBoxName = 'users';
//   static const String _settingsBoxName = 'settings';
//   static const String _directoryPathKey = 'directoryPath';
//   static const String _fieldConfigsKey =
//       'fieldConfigs'; // Key for fieldConfigs in settings box

//   Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     final appDir = await getApplicationDocumentsDirectory();
//     final appPath = appDir.path;

//     final storedPath = prefs.getString(_directoryPathKey) ?? appPath;
//     Hive.init(storedPath);

//     // Register adapters for custom types if needed
//     if (!Hive.isAdapterRegistered(FieldConfigAdapter().typeId)) {
//       Hive.registerAdapter(FieldConfigAdapter());
//     }

//     await Hive.openBox<Map>(_productBoxName);
//     await Hive.openBox<Map>(_billBoxName);
//     await Hive.openBox<Map>(_customerBoxName);
//     await Hive.openBox<Map>(_userBoxName);
//     await Hive.openBox(_settingsBoxName);
//   }

//   Future<void> setDirectoryPath(String newPath) async {
//     final prefs = await SharedPreferences.getInstance();
//     final oldPath = await directoryPath;

//     if (oldPath == newPath) return;

//     final oldHiveDir = Directory(oldPath);
//     final newHiveDir = Directory(newPath);

//     if (!await newHiveDir.exists()) {
//       await newHiveDir.create(recursive: true);
//     }

//     await Hive.close();

//     for (var entity in oldHiveDir.listSync()) {
//       if (entity is File) {
//         final newFile = File(
//           '${newHiveDir.path}/${entity.uri.pathSegments.last}',
//         );
//         await newFile.writeAsBytes(await entity.readAsBytes());
//       }
//     }

//     Hive.init(newPath);
//     await Hive.openBox<Map>(_productBoxName);
//     await Hive.openBox<Map>(_billBoxName);
//     await Hive.openBox<Map>(_customerBoxName);
//     await Hive.openBox<Map>(_userBoxName);
//     await Hive.openBox(_settingsBoxName);

//     await prefs.setString(_directoryPathKey, newPath);
//   }

//   Future<String> get directoryPath async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_directoryPathKey) ??
//         (await getApplicationDocumentsDirectory()).path;
//   }

//   Future<Box> getSettingsBox() async {
//     if (!Hive.isBoxOpen(_settingsBoxName)) {
//       return await Hive.openBox(_settingsBoxName);
//     }
//     return Hive.box(_settingsBoxName);
//   }

//   static Box<Map> get _productBox => Hive.box<Map>(_productBoxName);
//   static Box<Map> get _billBox => Hive.box<Map>(_billBoxName);
//   static Box<Map> get _customerBox => Hive.box<Map>(_customerBoxName);
//   static Box<Map> get _userBox => Hive.box<Map>(_userBoxName);
//   static Box get _settingsBox => Hive.box(_settingsBoxName);

//   // New methods for fieldConfigs
//   Future<void> saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
//     final settingsBox = await getSettingsBox();
//     // Convert FieldConfig objects to a map for storage
//     final fieldConfigsMap = fieldConfigs.map(
//       (key, value) => MapEntry(key, value.toMap()),
//     );
//     await settingsBox.put(_fieldConfigsKey, fieldConfigsMap);
//   }

//   Future<Map<String, FieldConfig>> getFieldConfigs() async {
//     final settingsBox = await getSettingsBox();
//     final fieldConfigsMap = settingsBox.get(_fieldConfigsKey);
//     if (fieldConfigsMap == null) {
//       // Return default field configs if none are stored
//       return {
//         'name': FieldConfig.initial('name', WidgetType.textField),
//         'price': FieldConfig.initial('price', WidgetType.textField),
//         'imageFile': FieldConfig.initial('imageFile', WidgetType.imagePicker),
//         'warranty': FieldConfig.initial('warranty', WidgetType.dropdown),
//         'condition': FieldConfig.initial('condition', WidgetType.dropdown),
//         'brand': FieldConfig.initial('brand', WidgetType.textField),
//         'description': FieldConfig.initial('description', WidgetType.textField),
//         'purchasePrice': FieldConfig.initial(
//           'purchasePrice',
//           WidgetType.textField,
//         ),
//         'stock': FieldConfig.initial('stock', WidgetType.textField),
//         'isBackup': FieldConfig.initial('isBackup', WidgetType.checkbox),
//       };
//     }
//     return (fieldConfigsMap as Map).map(
//       (key, value) =>
//           MapEntry(key, FieldConfig.fromMap(Map<String, dynamic>.from(value))),
//     );
//   }

//   List<Product> getProducts() {
//     return _productBox.values
//         .map((e) => Product.fromMap(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<void> addProduct(Product product) async {
//     await _productBox.put(product.id, product.toMap());
//   }

//   Future<void> updateProduct(Product product) async {
//     await _productBox.put(product.id, product.toMap());
//   }

//   Future<void> deleteProduct(String id) async {
//     await _productBox.delete(id);
//   }

//   List<Bill> getBills() {
//     final List<Bill> bills = [];
//     for (var value in _billBox.values) {
//       try {
//         final billMap = Map<String, dynamic>.from(value);
//         billMap['customerId'] ??= null;
//         billMap['paymentMethod'] ??= null;
//         bills.add(Bill.fromMap(billMap));
//       } catch (e) {
//         debugPrint('Error deserializing bill: $e');
//       }
//     }
//     return bills;
//   }

//   Future<void> saveBill(Bill bill) async {
//     await _billBox.put(bill.id, bill.toMap());
//   }

//   List<Customer> getCustomers() {
//     return _customerBox.values
//         .map((e) => Customer.fromMap(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<void> saveCustomer(Customer customer) async {
//     await _customerBox.put(customer.id, customer.toMap());
//   }

//   Future<void> updateCustomer(Customer customer) async {
//     await _customerBox.put(customer.id, customer.toMap());
//   }

//   Future<void> deleteCustomer(String id) async {
//     await _customerBox.delete(id);
//   }

//   List<User> getUsers() {
//     return _userBox.values
//         .map((e) => User.fromMap(Map<String, dynamic>.from(e)))
//         .toList();
//   }

//   Future<void> saveUser(User user) async {
//     await _userBox.put(user.id, user.toMap());
//   }

//   Future<void> updateUser(User user) async {
//     await _userBox.put(user.id, user.toMap());
//   }

//   Future<void> deleteUser(String id) async {
//     await _userBox.delete(id);
//   }

//   Future<void> clearAll() async {
//     await _productBox.clear();
//     await _billBox.clear();
//     await _customerBox.clear();
//     await _userBox.clear();
//     await _settingsBox.clear();
//   }

//   Future<void> deleteBill(String id) async {
//     await _billBox.delete(id);
//   }

//   Future<void> close() async {
//     await Hive.close();
//   }
// }

// // Hive Adapter for FieldConfig
// class FieldConfigAdapter extends TypeAdapter<FieldConfig> {
//   @override
//   final int typeId = 0; // Unique ID for FieldConfig

//   @override
//   FieldConfig read(BinaryReader reader) {
//     return FieldConfig(
//       isShow: reader.readBool(),
//       isRequired: reader.readBool(),
//       hintText: reader.readString(),
//       validatorText: reader.readString(),
//       title: reader.readString(),
//       widgetType: WidgetType.values.firstWhere(
//         (e) => e.toString() == reader.readString(),
//         orElse: () => WidgetType.textField,
//       ),
//     );
//   }

//   @override
//   void write(BinaryWriter writer, FieldConfig obj) {
//     writer.writeBool(obj.isShow);
//     writer.writeBool(obj.isRequired);
//     writer.writeString(obj.hintText);
//     writer.writeString(obj.validatorText);
//     writer.writeString(obj.title);
//     writer.writeString(obj.widgetType.toString());
//   }
// }

// class DatabaseService {
//   final HiveService _hiveService;

//   DatabaseService() : _hiveService = HiveService();

//   Future<void> initialize() async {
//     await _hiveService.init();
//   }

//   Future<List<Product>> getProducts() async {
//     return _hiveService.getProducts();
//   }

//   Future<void> addProduct(Product product) async {
//     await _hiveService.addProduct(product);
//   }

//   Future<void> updateProduct(Product product) async {
//     await _hiveService.updateProduct(product);
//   }

//   Future<void> deleteProduct(String id) async {
//     await _hiveService.deleteProduct(id);
//   }

//   Future<void> saveBill(Bill bill) async {
//     await _hiveService.saveBill(bill);
//   }

//   Future<List<Bill>> getBills() async {
//     return _hiveService.getBills();
//   }

//   Future<List<Customer>> getCustomers() async {
//     return _hiveService.getCustomers();
//   }

//   Future<void> saveCustomer(Customer customer) async {
//     await _hiveService.saveCustomer(customer);
//   }

//   Future<void> updateCustomer(Customer customer) async {
//     await _hiveService.updateCustomer(customer);
//   }

//   Future<void> deleteCustomer(String id) async {
//     await _hiveService.deleteCustomer(id);
//   }

//   Future<List<User>> getUsers() async {
//     return _hiveService.getUsers();
//   }

//   Future<void> saveUser(User user) async {
//     await _hiveService.saveUser(user);
//   }

//   Future<void> updateUser(User user) async {
//     await _hiveService.updateUser(user);
//   }

//   Future<void> deleteUser(String id) async {
//     await _hiveService.deleteUser(id);
//   }

//   Future<void> clearAllData() async {
//     await _hiveService.clearAll();
//   }

//   Future<void> setNewDirectory(String newPath) async {
//     await _hiveService.setDirectoryPath(newPath);
//   }

//   Future<String> getCurrentHivePath() async {
//     return await _hiveService.directoryPath;
//   }

//   Future<void> deleteBill(String id) async {
//     await _hiveService.deleteBill(id);
//   }

//   Future<void> close() async {
//     await _hiveService.close();
//   }

//   // New methods for fieldConfigs
//   Future<void> saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
//     await _hiveService.saveFieldConfigs(fieldConfigs);
//   }

//   Future<Map<String, FieldConfig>> getFieldConfigs() async {
//     return await _hiveService.getFieldConfigs();
//   }
// }
