// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:open_file/open_file.dart';
import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../models/items_model.dart';
import '../../utils/payment_calculator.dart';
import '../../view_models/providers/bills_provider.dart';
import '../../view_models/providers/customer_prvider.dart';
import '../../view_models/providers/sales_provider.dart'
    hide databaseServiceProvider;
import '../../view_models/providers/settings_provider.dart'
    hide hiveServiceProvider;
import '../../view_models/services/database/database_services.dart';
import '../../view_models/states/sales_state.dart';
import '../bills/widgets/pdf_genrater_widget.dart';
import '../bills/widgets/thermal_print_widget.dart';
import 'check_out_view.dart';
import 'mobile_cart_page.dart';
import 'widgets/cart_section_widget.dart';
import 'widgets/product_section_with_search.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  late final DatabaseService dbService; // Store provider instance
  late final HiveService hiveService; // Store provider instance

  @override
  void initState() {
    super.initState();
    // Initialize provider instances
    dbService = ref.read(databaseServiceProvider);
    hiveService = ref.read(hiveServiceProvider);
  }

  Future<void> _completeSale() async {
    if (!mounted) return;
    final salesState = ref.read(salesProvider);
    if (salesState.cartItems.isEmpty) {
      if (mounted) {
        AppFlushbar.warning(context, message: 'Cart is empty');
      }
      return;
    }

    debugPrint(
      '🟢 SALES: Opening checkout with total: ${salesState.totalAmount}, discount: ${salesState.discount}',
    );
    debugPrint(
      '🟢 SALES: Current paid amount BEFORE checkout: ${salesState.paidAmount}',
    );
    debugPrint(
      '🟢 SALES: Current isPaid BEFORE checkout: ${salesState.isPaid}',
    );

    final customerData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => CustomerPaymentScreen(
              totalAmount: salesState.totalAmount,
              discount: salesState.discount,
            ),
      ),
    );

    debugPrint('🟢 SALES: Returned from checkout');
    if (customerData == null || !mounted) return;
    debugPrint('🟢 SALES: Customer data received: $customerData');

    // Read salesState AGAIN after returning from checkout
    final updatedSalesState = ref.read(salesProvider);
    debugPrint(
      '🟢 SALES: Paid amount AFTER checkout: ${updatedSalesState.paidAmount}',
    );
    debugPrint('🟢 SALES: isPaid AFTER checkout: ${updatedSalesState.isPaid}');
    debugPrint(
      '🟢 SALES: Payment method AFTER checkout: ${updatedSalesState.paymentMethod}',
    );

    final isTestBill = customerData['isTestBill'] as bool? ?? false;

    if (isTestBill) {
      // Test bill: only generate PDF, skip saving customer/bill/stock
      final tempCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: customerData['name'] as String? ?? 'TEST',
        address: '',
        phoneNumber: '',
      );
      final bill = _createBill(
        tempCustomer,
        updatedSalesState.isPaid,
        updatedSalesState.paymentMethod,
      );
      await _handleSaleAction(bill);
      if (mounted) {
        ref.read(salesProvider.notifier).resetCart();
      }
      return;
    }

    final customer = await _saveOrUpdateCustomer(customerData);
    if (!mounted) return;

    final bill = _createBill(
      customer,
      updatedSalesState.isPaid,
      updatedSalesState.paymentMethod,
    );
    await _saveSale(bill, customer);
    if (!mounted) return;

    await _handleSaleAction(bill);
    if (mounted) {
      ref.read(salesProvider.notifier).resetCart();
    }
  }

  /// Process checkout result from MobileCartPage
  Future<void> _processCheckoutResult(Map<String, dynamic> customerData) async {
    if (!mounted) return;
    debugPrint('🟢 SALES: Processing checkout result: $customerData');

    // Read salesState after returning from checkout
    final updatedSalesState = ref.read(salesProvider);
    debugPrint(
      '🟢 SALES: Paid amount AFTER checkout: ${updatedSalesState.paidAmount}',
    );
    debugPrint('🟢 SALES: isPaid AFTER checkout: ${updatedSalesState.isPaid}');
    debugPrint(
      '🟢 SALES: Payment method AFTER checkout: ${updatedSalesState.paymentMethod}',
    );

    final isTestBill = customerData['isTestBill'] as bool? ?? false;

    if (isTestBill) {
      // Test bill: only generate PDF, skip saving customer/bill/stock
      final tempCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: customerData['name'] as String? ?? 'TEST',
        address: '',
        phoneNumber: '',
      );
      final bill = _createBill(
        tempCustomer,
        updatedSalesState.isPaid,
        updatedSalesState.paymentMethod,
      );
      await _handleSaleAction(bill);
      if (mounted) {
        ref.read(salesProvider.notifier).resetCart();
      }
      return;
    }

    final customer = await _saveOrUpdateCustomer(customerData);
    if (!mounted) return;

    final bill = _createBill(
      customer,
      updatedSalesState.isPaid,
      updatedSalesState.paymentMethod,
    );
    await _saveSale(bill, customer);
    if (!mounted) return;

    await _handleSaleAction(bill);
    if (mounted) {
      ref.read(salesProvider.notifier).resetCart();
    }
  }

  // Future<Customer> _saveOrUpdateCustomer(
  //   Map<String, String> customerData,
  // ) async {
  //   if (!mounted) {
  //     return Customer(id: '', name: '', address: '', phoneNumber: '');
  //   }
  //   final customers = await dbService.getCustomers();
  //   final existingCustomer = customers.firstWhere(
  //     (customer) =>
  //         customer.name.toLowerCase() == customerData['name']!.toLowerCase(),
  //     orElse:
  //         () => Customer(
  //           id: DateTime.now().millisecondsSinceEpoch.toString(),
  //           name: customerData['name']!,
  //           address: customerData['address'] ?? '',
  //           phoneNumber: customerData['phoneNumber'] ?? '',
  //         ),
  //   );

  //   final updatedCustomer = Customer(
  //     id: existingCustomer.id,
  //     name: existingCustomer.name,
  //     address:
  //         customerData['address']?.isNotEmpty == true
  //             ? customerData['address']!
  //             : existingCustomer.address,
  //     phoneNumber:
  //         customerData['phoneNumber']?.isNotEmpty == true
  //             ? customerData['phoneNumber']!
  //             : existingCustomer.phoneNumber,
  //     visitCount: existingCustomer.visitCount + 1,
  //     billIds: [
  //       ...existingCustomer.billIds,
  //       DateTime.now().millisecondsSinceEpoch.toString(),
  //     ],
  //   );

  //   if (mounted) {
  //     if (customers.contains(existingCustomer)) {
  //       await dbService.updateCustomer(updatedCustomer);
  //     } else {
  //       await dbService.saveCustomer(updatedCustomer);
  //     }
  //   }

  //   return updatedCustomer;
  // }

  Future<Customer> _saveOrUpdateCustomer(
    Map<String, dynamic> customerData,
  ) async {
    if (!mounted) {
      return Customer(id: '', name: '', address: '', phoneNumber: '');
    }

    final isWalkIn = customerData['isWalkIn'] as bool? ?? false;
    final name = customerData['name'] as String? ?? '';
    final address = customerData['address'] as String? ?? '';
    final phoneNumber = customerData['phoneNumber'] as String? ?? '';

    if (isWalkIn) {
      // For walk-in customers, return a temporary customer object without saving
      return Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: '',
        phoneNumber: '',
        visitCount: 1,
        billIds: [DateTime.now().millisecondsSinceEpoch.toString()],
      );
    }

    final customers = await dbService.getCustomers();
    final existingCustomer = customers.firstWhere(
      (customer) => customer.name.toLowerCase() == name.toLowerCase(),
      orElse:
          () => Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            address: address,
            phoneNumber: phoneNumber,
            visitCount: 0,
            billIds: [],
          ),
    );

    final updatedCustomer = Customer(
      id: existingCustomer.id,
      name: name,
      address: address.isNotEmpty ? address : existingCustomer.address,
      phoneNumber:
          phoneNumber.isNotEmpty ? phoneNumber : existingCustomer.phoneNumber,
      visitCount: existingCustomer.visitCount + 1,
      billIds: [
        ...existingCustomer.billIds,
        DateTime.now().millisecondsSinceEpoch.toString(),
      ],
    );

    if (mounted) {
      if (customers.contains(existingCustomer)) {
        await dbService.updateCustomer(updatedCustomer);
      } else {
        await dbService.saveCustomer(updatedCustomer);
      }
    }

    return updatedCustomer;
  }

  Bill _createBill(Customer customer, bool isPaid, String? paymentMethod) {
    final salesState = ref.read(salesProvider);
    final finalAmount = PaymentCalculator.calculateTotalAfterDiscount(
      totalAmount: salesState.totalAmount,
      discount: salesState.discount,
    );
    final paidAmount = isPaid ? finalAmount : salesState.paidAmount;

    // Use PaymentCalculator for consistent status determination
    final billStatus = PaymentCalculator.calculatePaymentStatus(
      totalAmount: salesState.totalAmount,
      discount: salesState.discount,
      paidAmount: paidAmount,
    );

    return Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      items: salesState.cartItems.keys.toList(),
      quantities: salesState.cartItems.map(
        (key, value) => MapEntry(key.id, value),
      ),
      totalAmount: salesState.totalAmount,
      discount: salesState.discount,
      paidAmount: paidAmount,
      customerName: customer.name,
      customerId: customer.id,
      status: billStatus,
      paymentMethod: paymentMethod,
    );
  }

  Future<void> _saveSale(Bill bill, Customer customer) async {
    if (!mounted) return;
    await dbService.saveBill(bill);

    // Refresh bills and customers list after saving
    if (mounted) {
      ref.read(billsProvider.notifier).fetchBills();
      ref.read(customersProvider.notifier).refresh();
    }

    // Update stock for non-service products
    for (var entry in bill.quantities.entries) {
      final product = bill.items.firstWhere((p) => p.id == entry.key);

      // Only update stock for products (not services)
      if (!product.isService) {
        final newStock = (product.stock ?? 0) - entry.value;
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          stock: newStock >= 0 ? newStock : 0,
          description: product.description,
          imageUrl: product.imageUrl,
          isService: product.isService,
          purchasePrice: product.purchasePrice,
          isBackup: product.isBackup,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
          warranty: product.warranty,
          condition: product.condition,
          brand: product.brand,
          category: product.category,
          fieldConfigs: product.fieldConfigs,
        );
        if (mounted) {
          await dbService.updateProduct(updatedProduct);
        }
      }
    }

    // Invalidate products provider to trigger refresh in UI
    if (mounted) {
      ref.invalidate(productsFutureProvider);
    }
  }

  Future<void> _handleSaleAction(Bill bill) async {
    if (!mounted) return;
    final settingsState = ref.read(settingsProvider);
    final salesState = ref.read(salesProvider);

    // Check if printing is enabled
    if (!settingsState.isPrintEnabled) {
      return; // Skip if printing is disabled
    }

    // Check print format and print accordingly
    if (settingsState.printFormat == PrintFormat.pdf) {
      // PDF printing
      final dbService = ref.read(databaseServiceProvider);
      final users = await dbService.getUsers();

      Uint8List? shopLogo;
      String? ownerName;
      String? shopName;
      String? phoneNumber;
      String? tagline;
      String? bankName;
      String? accountNumber;
      String? ifscCode;
      Uint8List? bankQrCode;
      Map<String, String>? socialMediaHandles;
      Uint8List? facebookIcon;
      Uint8List? instagramIcon;
      Uint8List? twitterIcon;
      Uint8List? whatsappIcon;

      if (users.isNotEmpty) {
        final user = users.first;
        ownerName = user.ownerName;
        shopName = user.shopName;
        phoneNumber = user.phoneNumber;
        tagline = user.shopTagline;

        // Load shop logo if exists
        if (user.shopLogoPath != null && user.shopLogoPath!.isNotEmpty) {
          final logoFile = File(user.shopLogoPath!);
          if (await logoFile.exists()) {
            shopLogo = await logoFile.readAsBytes();
          }
        }

        // Load bank details based on settings (if enabled and bank exists)
        if (settingsState.showBankDetailsOnBill &&
            user.bankDetails.isNotEmpty) {
          // Use selected bank index from settings, fallback to first bank
          final bankIndex = settingsState.selectedBankIndex.clamp(
            0,
            user.bankDetails.length - 1,
          );
          final selectedBank = user.bankDetails[bankIndex];
          bankName = selectedBank.bankName;
          accountNumber = selectedBank.accountNumber;
          ifscCode = selectedBank.ifscCode;

          // Load bank QR code if exists
          if (selectedBank.qrCodePath != null &&
              selectedBank.qrCodePath!.isNotEmpty) {
            final qrFile = File(selectedBank.qrCodePath!);
            if (await qrFile.exists()) {
              bankQrCode = await qrFile.readAsBytes();
            }
          }
        }

        // Load social media handles from user profile
        socialMediaHandles = {};
        if (user.facebook != null && user.facebook!.isNotEmpty) {
          socialMediaHandles['facebook'] = user.facebook!;
        }
        if (user.instagram != null && user.instagram!.isNotEmpty) {
          socialMediaHandles['instagram'] = user.instagram!;
        }
        if (user.twitter != null && user.twitter!.isNotEmpty) {
          socialMediaHandles['twitter'] = user.twitter!;
        }
        if (user.whatsapp != null && user.whatsapp!.isNotEmpty) {
          socialMediaHandles['whatsapp'] = user.whatsapp!;
        }
      }

      // Load watermark image from assets if watermark is enabled
      Uint8List? watermarkImage;
      if (settingsState.showBackgroundWatermark) {
        try {
          final byteData = await rootBundle.load('assets/paid stamp.png');
          watermarkImage = byteData.buffer.asUint8List();
        } catch (e) {
          debugPrint('Error loading watermark image: $e');
        }
      }

      // Load social media icons from assets (for modern design)
      if (settingsState.billDesign == BillDesign.modern &&
          socialMediaHandles != null &&
          socialMediaHandles.isNotEmpty) {
        try {
          if (socialMediaHandles.containsKey('facebook')) {
            final data = await rootBundle.load('assets/icons8-facebook-96.png');
            facebookIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('instagram')) {
            final data = await rootBundle.load('assets/instagram-.png');
            instagramIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('twitter')) {
            final data = await rootBundle.load('assets/x.png');
            twitterIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('whatsapp')) {
            final data = await rootBundle.load('assets/whatsapp.png');
            whatsappIcon = data.buffer.asUint8List();
          }
        } catch (e) {
          debugPrint('Error loading social media icons: $e');
        }
      }

      final pdfGenerator = ReceiptPDFGenerator(
        bill: bill,
        shopName: shopName ?? "",
        shopLogo: shopLogo,
        ownerName: ownerName,
        phoneNumber: phoneNumber,
        tagline: tagline,
        bankName: bankName,
        accountNumber: accountNumber,
        ifscCode: ifscCode,
        bankQrCode: bankQrCode,
        billDesign: settingsState.billDesign,
        showPaidStamp: settingsState.showPaidStamp,
        paidStampText: settingsState.paidStampText,
        paidStampSignature: settingsState.paidStampSignature,
        showDateOnStamp: settingsState.showDateOnStamp,
        showBackgroundWatermark: settingsState.showBackgroundWatermark,
        watermarkOpacity: settingsState.watermarkOpacity,
        watermarkImage: watermarkImage,
        socialMediaHandles: socialMediaHandles,
        facebookIcon: facebookIcon,
        instagramIcon: instagramIcon,
        twitterIcon: twitterIcon,
        whatsappIcon: whatsappIcon,
      );
      final pdf = pdfGenerator.generatePDF();
      final directoryPath = await hiveService.directoryPath;
      final file = File(
        '$directoryPath/invoices/invoice_${bill.id.substring(0, 8)}.pdf',
      );

      final directory = Directory('$directoryPath/invoices');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        await OpenFile.open(file.path);
      }
    } else if (settingsState.printFormat == PrintFormat.thermal) {
      // Thermal printing
      if (salesState.selectedPrinter != null) {
        // Load shop info for thermal receipt
        final dbService = ref.read(databaseServiceProvider);
        final users = await dbService.getUsers();
        String? shopName;
        Uint8List? shopLogo;

        if (users.isNotEmpty) {
          final user = users.first;
          shopName = user.shopName;
          if (user.shopLogoPath != null && user.shopLogoPath!.isNotEmpty) {
            final logoFile = File(user.shopLogoPath!);
            if (await logoFile.exists()) {
              shopLogo = await logoFile.readAsBytes();
            }
          }
        }

        final thermalPrinter = ThermalReceiptPrinter(
          bill: bill,
          context: context,
          design: settingsState.thermalDesign,
          shopName: shopName,
          shopLogo: shopLogo,
        );
        if (mounted) {
          ref.read(salesProvider.notifier).setPrintingThermal(true);
          await thermalPrinter.printThermal(salesState.selectedPrinter, () {
            if (mounted) {
              ref.read(salesProvider.notifier).setPrintingThermal(false);
            }
          });
        }
      } else {
        if (mounted) {
          AppFlushbar.warning(
            context,
            message:
                'No thermal printer selected. Please select a printer in settings.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(salesProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTab =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1100;

        return Scaffold(
          appBar: AppBarWidget.customAppBar(
            context: context,
            automaticallyImplyLeading: false,
            title: 'Sales',
            actions: [],
          ),
          body: Padding(
            padding: EdgeInsets.all(0.h),
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  flex:
                      isMobile
                          ? 1
                          : isTab
                          ? 2
                          : 3,
                  child: buildProductsSectionWithSearch(ref),
                ),
                // Show cart section only on tablet and desktop
                if (!isMobile && salesState.cartItems.isNotEmpty) ...[
                  SizedBox(width: 2.w),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.grey800
                                : AppColors.grey200),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: SizedBox.expand(
                        child: buildCartSection(
                          constraints,
                          ref,
                          _completeSale,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Show FAB on mobile when cart has items
          floatingActionButton:
              isMobile && salesState.cartItems.isNotEmpty
                  ? FloatingActionButton.extended(
                    onPressed: () async {
                      final result =
                          await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const MobileCartBottomSheet(),
                          );
                      // Process the checkout result if available
                      if (result != null && mounted) {
                        await _processCheckoutResult(result);
                      }
                    },
                    backgroundColor: AppColors.primary,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          TablerIcons.shopping_cart,
                          color: Colors.white,
                          size: 24.spMin,
                        ),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: EdgeInsets.all(4.h),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${salesState.cartItems.length}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.spMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    label: Text(
                      'Rs.${(salesState.totalAmount - salesState.discount).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.spMin,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
        );
      },
    );
  }
}

class PaymentContaienr extends StatelessWidget {
  final Function()? onTap;
  final String title;
  final SalesState salesState;
  final bool
  isPaymentStatus; // Add this to differentiate between payment method and status

  const PaymentContaienr({
    super.key,
    required this.salesState,
    this.onTap,
    required this.title,
    this.isPaymentStatus = false, // Default to false (for payment method)
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this container is selected based on whether it's for payment status or method
    final bool isSelected =
        isPaymentStatus
            ? (title == 'Paid' && salesState.isPaid) ||
                (title == 'Pending' && !salesState.isPaid)
            : salesState.paymentMethod == title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight1 : AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.spMin,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.background : AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis, // Handle overflow
          maxLines: 1, // Limit to 1 line to prevent overflow
        ),
      ),
    );
  }
}
