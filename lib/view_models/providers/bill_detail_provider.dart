import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thermal_printer/thermal_printer.dart';
import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../services/database/database_services.dart'
    hide databaseServiceProvider;
import '../states/bill_detail_state.dart';
import 'add_prduct_provider.dart'; // For databaseServiceProvider
import 'package:riverpod/legacy.dart';

class BillDetailNotifier extends StateNotifier<BillDetailState> {
  final DatabaseService _databaseService;
  final Bill bill;
  final PrinterManager _printerManager = PrinterManager.instance;
  StreamSubscription<PrinterDevice>? _printerSubscription;

  BillDetailNotifier(this._databaseService, this.bill)
    : super(BillDetailState());

  // Load customer data
  Future<void> loadCustomer() async {
    if (bill.customerId == null) return;

    try {
      state = state.copyWith(isLoading: true);
      final customers = await _databaseService.getCustomers();
      final customer = customers.firstWhere(
        (c) => c.id == bill.customerId,
        orElse:
            () => Customer(
              id: '',
              name: bill.customerName ?? 'Unknown',
              address: '',
              phoneNumber: '',
            ),
      );
      state = state.copyWith(customer: customer, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
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

  void selectPrinter(PrinterDevice? printer) {
    state = state.copyWith(
      selectedPrinter: printer,
      clearSelectedPrinter: printer == null,
    );
  }

  void setPrintingThermal(bool isPrinting) {
    state = state.copyWith(isPrintingThermal: isPrinting);
  }

  @override
  void dispose() {
    _printerSubscription?.cancel();
    super.dispose();
  }
}

final billDetailProvider = StateNotifierProvider.family<
  BillDetailNotifier,
  BillDetailState,
  Bill
>((ref, bill) => BillDetailNotifier(ref.read(databaseServiceProvider), bill));
