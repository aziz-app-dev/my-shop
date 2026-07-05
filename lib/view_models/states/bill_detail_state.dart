import 'package:thermal_printer/thermal_printer.dart';
import '../../models/coustomer_model.dart';

class BillDetailState {
  final Customer? customer;
  final bool isLoading;
  final List<PrinterDevice> printers;
  final PrinterDevice? selectedPrinter;
  final bool isPrintingThermal;

  BillDetailState({
    this.customer,
    this.isLoading = false,
    this.printers = const [],
    this.selectedPrinter,
    this.isPrintingThermal = false,
  });

  BillDetailState copyWith({
    Customer? customer,
    bool? isLoading,
    bool clearCustomer = false,
    List<PrinterDevice>? printers,
    PrinterDevice? selectedPrinter,
    bool? isPrintingThermal,
    bool clearSelectedPrinter = false,
  }) {
    return BillDetailState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      isLoading: isLoading ?? this.isLoading,
      printers: printers ?? this.printers,
      selectedPrinter: clearSelectedPrinter ? null : (selectedPrinter ?? this.selectedPrinter),
      isPrintingThermal: isPrintingThermal ?? this.isPrintingThermal,
    );
  }
}
