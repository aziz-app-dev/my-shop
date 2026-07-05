import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:thermal_printer/esc_pos_utils_platform/esc_pos_utils_platform.dart';
import 'package:image/image.dart' as img;
import '../../../models/bills_model.dart';
import '../../../view_models/providers/settings_provider.dart';

class ThermalReceiptPrinter {
  final Bill bill;
  final BuildContext context;
  final ThermalDesign design;
  final String? shopName;
  final Uint8List? shopLogo;
  final PrinterManager _printerManager = PrinterManager.instance;

  ThermalReceiptPrinter({
    required this.bill,
    required this.context,
    this.design = ThermalDesign.classic,
    this.shopName,
    this.shopLogo,
  });

  /// Scan for available USB printers
  Stream<PrinterDevice> scanForPrinters() {
    return _printerManager.discovery(type: PrinterType.usb);
  }

  /// Print the receipt to the selected printer
  Future<void> printThermal(PrinterDevice? printer, VoidCallback onComplete) async {
    if (printer == null) {
      debugPrint('No printer selected');
      onComplete();
      return;
    }

    try {
      // Connect to printer
      final isConnected = await _printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: printer.name,
          productId: printer.productId,
          vendorId: printer.vendorId,
        ),
      );

      if (!isConnected) {
        debugPrint('Failed to connect to printer');
        onComplete();
        return;
      }

      // Generate receipt data
      final receiptBytes = await _generateReceiptBytes();

      // Send to printer
      await _printerManager.send(type: PrinterType.usb, bytes: receiptBytes);

      // Disconnect
      await _printerManager.disconnect(type: PrinterType.usb);

      onComplete();
    } catch (e) {
      debugPrint('Error printing: $e');
      try {
        await _printerManager.disconnect(type: PrinterType.usb);
      } catch (_) {}
      onComplete();
    }
  }

  Future<List<int>> _generateReceiptBytes() async {
    if (design == ThermalDesign.classic) {
      return _generateClassicReceipt();
    } else {
      return _generateMinimalReceipt();
    }
  }

  /// Classic design - Full featured with shop name, detailed layout, prices per item
  Future<List<int>> _generateClassicReceipt() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Shop Logo (if available)
    if (shopLogo != null) {
      try {
        final image = img.decodeImage(shopLogo!);
        if (image != null) {
          bytes += generator.image(image, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (e) {
        debugPrint('Error printing logo: $e');
      }
    }

    // Shop Name Header
    bytes += generator.text(
      shopName ?? 'RECEIPT',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    bytes += generator.hr();

    // Invoice info
    bytes += generator.text(
      'Invoice #${bill.id.substring(0, 8)}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(bill.dateTime)}',
      styles: const PosStyles(align: PosAlign.left),
    );

    // Customer info
    if (bill.customerName != null && bill.customerName!.isNotEmpty) {
      bytes += generator.text(
        'Customer: ${bill.customerName}',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    bytes += generator.hr();

    // Items header with Price column
    bytes += generator.row([
      PosColumn(text: 'Item', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Price', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    // Items with unit price
    for (var item in bill.items) {
      final qty = bill.quantities[item.id] ?? 1;
      final total = item.price * qty;
      bytes += generator.row([
        PosColumn(text: item.name.length > 10 ? item.name.substring(0, 10) : item.name, width: 4),
        PosColumn(text: 'Rs.${item.price.toStringAsFixed(2)}', width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: 'Rs.${total.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Subtotal
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs.${bill.totalAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    // Discount
    if (bill.discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8),
        PosColumn(text: '-Rs.${bill.discount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    // Total
    final totalAfterDiscount = bill.totalAmount - bill.discount;
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 8, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: 'Rs.${totalAfterDiscount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    bytes += generator.hr();

    // Payment info
    if (bill.paidAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Paid:', width: 8),
        PosColumn(text: 'Rs.${bill.paidAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    final pendingAmount = totalAfterDiscount - bill.paidAmount;
    if (pendingAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Balance Due:', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Rs.${pendingAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.hr();

    // Status
    bytes += generator.text(
      'Status: ${bill.status}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    if (bill.paymentMethod != null) {
      bytes += generator.text(
        'Payment Method: ${bill.paymentMethod}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.feed(1);

    // Footer
    bytes += generator.text(
      '================================',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Thank you for your business!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Please come again',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Minimal design - Simple text-based receipt
  Future<List<int>> _generateMinimalReceipt() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Simple Header
    bytes += generator.text(
      'RECEIPT',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);

    // Invoice info
    bytes += generator.text(
      'Invoice #${bill.id.substring(0, 8)}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(bill.dateTime)}',
      styles: const PosStyles(align: PosAlign.left),
    );

    // Customer info
    if (bill.customerName != null && bill.customerName!.isNotEmpty) {
      bytes += generator.text(
        'Customer: ${bill.customerName}',
        styles: const PosStyles(align: PosAlign.left),
      );
    }

    bytes += generator.hr();

    // Items header
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    // Items (simplified - no unit price)
    for (var item in bill.items) {
      final qty = bill.quantities[item.id] ?? 1;
      final total = item.price * qty;
      bytes += generator.row([
        PosColumn(text: item.name.length > 14 ? item.name.substring(0, 14) : item.name, width: 6),
        PosColumn(text: qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: 'Rs.${total.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr();

    // Total only (no subtotal in minimal)
    final totalAfterDiscount = bill.totalAmount - bill.discount;
    if (bill.discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 8),
        PosColumn(text: '-Rs.${bill.discount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 8, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: 'Rs.${totalAfterDiscount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    // Status
    bytes += generator.text(
      'Status: ${bill.status}',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(1);

    // Simple Footer
    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
