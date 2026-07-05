import 'package:thermal_printer/thermal_printer.dart';
import '../../models/items_model.dart';

class SalesState {
  final Map<Product, int> cartItems;
  final bool isPaid;
  final double totalAmount;
  final String? paymentMethod;
  final double discount;
  final double paidAmount;
  final List<PrinterDevice> printers;
  final PrinterDevice? selectedPrinter;
  final bool isPrintingThermal;

  SalesState({
    this.cartItems = const {},
    required this.isPaid,
    this.totalAmount = 0.0,
    this.paymentMethod,
    this.discount = 0.0,
    this.paidAmount = 0.0,
    this.printers = const [],
    this.selectedPrinter,
    this.isPrintingThermal = false,
  });

  SalesState copyWith({
    Map<Product, int>? cartItems,
    bool? isPaid,
    double? totalAmount,
    String? paymentMethod,
    double? discount,
    double? paidAmount,
    List<PrinterDevice>? printers,
    PrinterDevice? selectedPrinter,
    bool? isPrintingThermal,
    bool clearSelectedPrinter = false,
  }) {
    return SalesState(
      cartItems: cartItems ?? this.cartItems,
      isPaid: isPaid ?? this.isPaid,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
      printers: printers ?? this.printers,
      selectedPrinter: clearSelectedPrinter ? null : (selectedPrinter ?? this.selectedPrinter),
      isPrintingThermal: isPrintingThermal ?? this.isPrintingThermal,
    );
  }
}
