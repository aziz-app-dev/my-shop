import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thermal_printer/thermal_printer.dart';
import '../../models/items_model.dart';
import '../services/database/database_services.dart';
import '../states/sales_state.dart';
import 'settings_provider.dart';
import 'package:riverpod/legacy.dart';

class SalesNotifier extends StateNotifier<SalesState> {
  final DatabaseService dbService;
  final SettingsState _settingsState;
  final PrinterManager _printerManager = PrinterManager.instance;
  StreamSubscription<PrinterDevice>? _printerSubscription;

  SalesNotifier(this.dbService, this._settingsState)
    : super(SalesState(isPaid: _settingsState.isPaid, paymentMethod: 'Cash')) {
    // Start scanning for printers if thermal printing is enabled
    if (_settingsState.isPrintEnabled && _settingsState.printFormat == PrintFormat.thermal) {
      scanForPrinters();
    }
  }

  Future<void> scanForPrinters() async {
    state = state.copyWith(printers: []);
    final printers = <PrinterDevice>[];
    await _printerSubscription?.cancel();
    _printerSubscription = _printerManager
        .discovery(type: PrinterType.usb)
        .listen(
          (device) {
            printers.add(device);
            if (mounted) {
              state = state.copyWith(printers: [...printers]);
            }
          },
          onError: (error) {
            debugPrint('Error scanning printers: $error');
          },
        );
  }

  @override
  void dispose() {
    _printerSubscription?.cancel();
    super.dispose();
  }

  void addToCart(Product product) {
    final newCartItems = Map<Product, int>.from(state.cartItems);
    if (newCartItems.containsKey(product)) {
      if (product.isService ||
          (product.stock != null && newCartItems[product]! < product.stock!)) {
        newCartItems[product] = newCartItems[product]! + 1;
      } else {
        debugPrint('Cannot add ${product.name}: stock limit reached');
        return;
      }
    } else {
      newCartItems[product] = 1;
    }

    state = state.copyWith(
      cartItems: newCartItems,
      totalAmount: state.totalAmount + product.price,
    );
  }

  void setPaymentMethod(String? paymentMethod) {
    state = state.copyWith(paymentMethod: paymentMethod);
  }

  void removeFromCart(Product product) {
    final newCartItems = Map<Product, int>.from(state.cartItems);
    if (newCartItems.containsKey(product)) {
      final currentQuantity = newCartItems[product]!;
      if (currentQuantity > 1) {
        newCartItems[product] = currentQuantity - 1;
      } else {
        newCartItems.remove(product);
      }
      state = state.copyWith(
        cartItems: newCartItems,
        totalAmount: state.totalAmount - product.price,
      );
    }
  }

  void setPaymentStatus(bool isPaid) {
    state = state.copyWith(isPaid: isPaid);
    if (isPaid && state.paymentMethod == null) {
      state = state.copyWith(paymentMethod: 'Cash');
    }
    if (!isPaid) {
      state = state.copyWith(paymentMethod: 'Cash');
    }
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount.clamp(0, state.totalAmount));
  }

  void setPaidAmount(double amount) {
    debugPrint('🟡 SalesProvider.setPaidAmount called with: $amount');
    debugPrint(
      '🟡 Current state BEFORE: paidAmount=${state.paidAmount}, total=${state.totalAmount}, discount=${state.discount}',
    );
    state = state.copyWith(paidAmount: amount);
    debugPrint('🟡 New state AFTER: paidAmount=${state.paidAmount}');
  }

  void selectPrinter(PrinterDevice? printer) {
    state = state.copyWith(
      selectedPrinter: printer,
      clearSelectedPrinter: printer == null,
    );
  }

  void setPrintingThermal(bool isPrinting) {
    state = state.copyWith(isPrintingThermal: isPrinting);
  }

  void resetCart() {
    state = state.copyWith(
      cartItems: {},
      totalAmount: 0.0,
      isPaid: _settingsState.isPaid,
      paymentMethod: 'Cash',
      discount: 0.0,
      paidAmount: 0.0,
    );
  }
}

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => DatabaseService(),
);

final salesProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  // Read settings ONCE at creation. Watching here would rebuild the notifier
  // and wipe the in-progress cart every time any app setting changed.
  final settingsState = ref.read(settingsProvider);
  return SalesNotifier(dbService, settingsState);
});

final productsFutureProvider = FutureProvider<List<Product>>((ref) {
  return ref.read(databaseServiceProvider).getProducts();
});
