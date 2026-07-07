import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../../../models/bills_model.dart';
import '../../../models/brand_model.dart';
import '../../../models/category_model.dart';
import '../../../models/coustomer_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/items_model.dart';

/// Central handle for all Firebase access.
///
/// Everything cloud-side (auth, Firestore data sync, backup, storage) goes
/// through this one service so there is a single place that knows the data
/// layout. Data is stored per-signed-in-user under:
///
///   users/{uid}                       -> profile document
///   users/{uid}/products/{id}
///   users/{uid}/brands/{id}
///   users/{uid}/categories/{id}
///   users/{uid}/customers/{id}
///   users/{uid}/bills/{id}
///   users/{uid}/expenses/{id}
///
/// Models are stored using their own `toMap()` output so the exact same shape
/// flows Hive <-> Firestore <-> backup (no separate cloud schema to maintain).
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Currently signed-in user's uid, or null if signed out.
  String? get uid => auth.currentUser?.uid;

  bool get isSignedIn => auth.currentUser != null;

  /// Collection names that mirror the local Hive boxes and the sync tables.
  static const List<String> dataCollections = [
    'brands',
    'categories',
    'products',
    'customers',
    'bills',
    'expenses',
  ];

  /// Root document for the signed-in user. Throws if signed out — callers that
  /// run before auth must guard with [isSignedIn].
  DocumentReference<Map<String, dynamic>> get userDoc {
    final id = uid;
    if (id == null) {
      throw StateError('FirebaseService.userDoc accessed while signed out');
    }
    return firestore.collection('users').doc(id);
  }

  /// A per-user data collection (e.g. `users/{uid}/products`).
  CollectionReference<Map<String, dynamic>> collection(String name) {
    return userDoc.collection(name);
  }

  // ---------------------------------------------------------------------------
  // Dummy data seeding (for testing)
  // ---------------------------------------------------------------------------

  /// Seed a batch of realistic dummy data into the signed-in user's Firestore
  /// space so the app can be exercised end-to-end without manual entry.
  ///
  /// Usage (e.g. from a debug button or a test):
  /// ```dart
  /// await FirebaseService.instance.seedDummyData();
  /// ```
  ///
  /// Idempotent-ish: every call writes fresh docs with new ids unless
  /// [clearFirst] is true, which wipes the user's data collections first.
  /// Safe no-op when signed out.
  Future<void> seedDummyData({bool clearFirst = false}) async {
    if (!isSignedIn) {
      debugPrint('seedDummyData skipped: no signed-in user');
      return;
    }

    if (clearFirst) {
      await clearAllData();
    }

    const uuid = Uuid();
    final now = DateTime.now();

    // --- Brands ---
    final brands = [
      Brand(id: uuid.v4(), name: 'Dell', createdAt: now, updatedAt: now),
      Brand(id: uuid.v4(), name: 'HP', createdAt: now, updatedAt: now),
      Brand(id: uuid.v4(), name: 'Logitech', createdAt: now, updatedAt: now),
    ];

    // --- Categories ---
    final categories = [
      Category(id: uuid.v4(), name: 'Laptops', createdAt: now, updatedAt: now),
      Category(
        id: uuid.v4(),
        name: 'Accessories',
        createdAt: now,
        updatedAt: now,
      ),
      Category(id: uuid.v4(), name: 'Services', createdAt: now, updatedAt: now),
    ];

    // --- Products ---
    final products = [
      Product(
        id: uuid.v4(),
        name: 'Dell Inspiron 15',
        price: 85000,
        purchasePrice: 72000,
        stock: 5,
        brand: 'Dell',
        category: 'Laptops',
        condition: 'New',
        warranty: true,
        description: 'Core i5, 8GB RAM, 512GB SSD',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'HP Wireless Mouse',
        price: 1200,
        purchasePrice: 800,
        stock: 40,
        brand: 'HP',
        category: 'Accessories',
        condition: 'New',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'Logitech Keyboard K380',
        price: 3500,
        purchasePrice: 2600,
        stock: 15,
        brand: 'Logitech',
        category: 'Accessories',
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: uuid.v4(),
        name: 'Laptop Screen Repair',
        price: 6000,
        isService: true,
        category: 'Services',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // --- Customers ---
    final customers = [
      Customer(
        id: uuid.v4(),
        name: 'Ahmed Khan',
        phoneNumber: '03001234567',
        address: 'Main Bazaar',
        visitCount: 3,
        totalPaidAmount: 90000,
      ),
      Customer(
        id: uuid.v4(),
        name: 'Sara Ali',
        phoneNumber: '03119876543',
        address: 'Gulberg',
        visitCount: 1,
        totalPendingAmount: 1200,
      ),
    ];

    // --- Bills ---
    final bills = [
      Bill(
        id: uuid.v4(),
        dateTime: now.subtract(const Duration(days: 1)),
        items: [products[1]],
        quantities: {products[1].id: 2},
        totalAmount: 2400,
        status: 'paid',
        paymentMethod: 'Cash',
        paidAmount: 2400,
        customerName: 'Ahmed Khan',
      ),
    ];

    // --- Expenses ---
    final expenses = [
      Expense(
        id: uuid.v4(),
        amount: 25000,
        categoryId: 'rent',
        categoryName: 'Rent',
        note: 'Shop Rent',
        date: now.subtract(const Duration(days: 5)),
      ),
      Expense(
        id: uuid.v4(),
        amount: 8000,
        categoryId: 'utilities',
        categoryName: 'Utilities',
        note: 'Electricity Bill',
        date: now.subtract(const Duration(days: 2)),
      ),
    ];

    await _writeAll('brands', {for (final b in brands) b.id: b.toMap()});
    await _writeAll('categories', {for (final c in categories) c.id: c.toMap()});
    await _writeAll('products', {for (final p in products) p.id: p.toMap()});
    await _writeAll('customers', {for (final c in customers) c.id: c.toMap()});
    await _writeAll('bills', {for (final b in bills) b.id: b.toMap()});
    await _writeAll('expenses', {for (final e in expenses) e.id: e.toMap()});

    debugPrint(
      'seedDummyData: wrote ${brands.length} brands, '
      '${categories.length} categories, ${products.length} products, '
      '${customers.length} customers, ${bills.length} bills, '
      '${expenses.length} expenses',
    );
  }

  /// Batch-write a map of id -> data into a user data collection.
  Future<void> _writeAll(
    String collectionName,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    final batch = firestore.batch();
    final col = collection(collectionName);
    docs.forEach((id, data) {
      batch.set(col.doc(id), _sanitize(data));
    });
    await batch.commit();
  }

  /// Delete every document in the signed-in user's data collections.
  Future<void> clearAllData() async {
    if (!isSignedIn) return;
    for (final name in dataCollections) {
      final snapshot = await collection(name).get();
      if (snapshot.docs.isEmpty) continue;
      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Firestore can't store nested `DateTime` inside lists/maps reliably across
  /// the app's map shapes, and the app already serializes dates as ISO strings
  /// in `toMap()`. Convert any stray `DateTime` values to ISO strings so the
  /// stored shape matches exactly what `fromMap()` expects everywhere.
  Map<String, dynamic> _sanitize(Map<String, dynamic> input) {
    dynamic convert(dynamic v) {
      if (v is DateTime) return v.toIso8601String();
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), convert(val)));
      }
      if (v is List) return v.map(convert).toList();
      return v;
    }

    return input.map((k, v) => MapEntry(k, convert(v)));
  }
}
