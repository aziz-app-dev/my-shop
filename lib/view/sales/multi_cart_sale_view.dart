// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:open_file/open_file.dart';
import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../models/items_model.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../utils/payment_calculator.dart';
import '../../view_models/providers/bills_provider.dart';
import '../../view_models/providers/customer_prvider.dart';
import '../../view_models/providers/multi_cart_provider.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider, hiveServiceProvider;
import '../../view_models/states/multi_cart_state.dart';
import '../bills/widgets/pdf_genrater_widget.dart';
import '../bills/widgets/thermal_print_widget.dart';
import 'check_out_view.dart';
import 'mobile_multi_cart_page.dart';
import 'widgets/multi_cart_section_widget.dart';
import 'widgets/multi_cart_product_section.dart';

class MultiCartSalesScreen extends ConsumerStatefulWidget {
  const MultiCartSalesScreen({super.key});

  @override
  ConsumerState<MultiCartSalesScreen> createState() =>
      _MultiCartSalesScreenState();
}

class _MultiCartSalesScreenState extends ConsumerState<MultiCartSalesScreen>
    with TickerProviderStateMixin {
  late final DatabaseService dbService;
  late final HiveService hiveService;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    dbService = ref.read(databaseServiceProvider);
    hiveService = ref.read(hiveServiceProvider);

    // Initialize TabController immediately to avoid showing loader
    final multiCartState = ref.read(multiCartProvider);
    final cartCount = multiCartState.carts.length;
    if (cartCount > 0) {
      // Find the index of the active cart
      final activeCartIndex =
          multiCartState.activeCart != null
              ? multiCartState.carts.indexWhere(
                (cart) => cart.id == multiCartState.activeCart!.id,
              )
              : 0;

      final initialIndex =
          activeCartIndex >= 0 && activeCartIndex < cartCount
              ? activeCartIndex
              : 0;

      _tabController = TabController(
        length: cartCount,
        vsync: this,
        initialIndex: initialIndex,
      );
      _tabController?.addListener(() {
        if (_tabController == null || _tabController!.indexIsChanging) return;

        final multiCartState = ref.read(multiCartProvider);
        if (_tabController!.index < multiCartState.carts.length) {
          final selectedCart = multiCartState.carts[_tabController!.index];
          ref.read(multiCartProvider.notifier).switchCart(selectedCart.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int cartCount) {
    if (cartCount == 0) return;

    final multiCartState = ref.read(multiCartProvider);

    // Find the index of the active cart
    final activeCartIndex =
        multiCartState.activeCart != null
            ? multiCartState.carts.indexWhere(
              (cart) => cart.id == multiCartState.activeCart!.id,
            )
            : 0;

    final targetIndex =
        activeCartIndex >= 0 && activeCartIndex < cartCount
            ? activeCartIndex
            : (cartCount - 1);

    // Only recreate if length changed
    if (_tabController?.length != cartCount) {
      _tabController?.dispose();
      _tabController = TabController(
        length: cartCount,
        vsync: this,
        initialIndex: targetIndex,
      );

      _tabController?.addListener(() {
        if (_tabController == null || _tabController!.indexIsChanging) return;

        final multiCartState = ref.read(multiCartProvider);
        if (_tabController!.index < multiCartState.carts.length) {
          final selectedCart = multiCartState.carts[_tabController!.index];
          ref.read(multiCartProvider.notifier).switchCart(selectedCart.id);
        }
      });

      // Force a rebuild to show the new tab immediately (important for mobile)
      if (mounted) {
        setState(() {});
      }
    } else if (_tabController != null && _tabController!.index != targetIndex) {
      // If length didn't change but active cart changed, just update the index
      _tabController!.animateTo(targetIndex);
    }
  }

  Future<void> _completeSaleForCart(CartSession cart) async {
    if (!mounted) return;

    if (cart.cartItems.isEmpty) {
      if (mounted) {
        AppFlushbar.warning(context, message: 'Cart is empty');
      }
      return;
    }

    // Navigate to checkout with cart data
    final customerData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (context) => CustomerPaymentScreen(
              totalAmount: cart.totalAmount,
              discount: cart.discount,
            ),
      ),
    );

    if (customerData == null || !mounted) return;

    final isTestBill = customerData['isTestBill'] as bool? ?? false;

    if (isTestBill) {
      // Test bill: only generate PDF, skip saving customer/bill/stock
      final tempCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: customerData['name'] as String? ?? 'TEST',
        address: '',
        phoneNumber: '',
      );
      final bill = _createBill(cart, tempCustomer);
      await _handleSaleAction(bill);
      if (mounted) {
        ref.read(multiCartProvider.notifier).clearActiveCart();
        AppFlushbar.info(
          context,
          message: 'Test bill generated (no data saved)',
        );
      }
      return;
    }

    final customer = await _saveOrUpdateCustomer(customerData);
    if (!mounted) return;

    final bill = _createBill(cart, customer);
    await _saveSale(bill, customer);
    if (!mounted) return;

    await _handleSaleAction(bill);

    // Remove completed cart
    if (mounted) {
      ref.read(multiCartProvider.notifier).clearActiveCart();
      AppFlushbar.success(
        context,
        message: 'Sale completed for ${customer.name}',
      );
    }
  }

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

  Bill _createBill(CartSession cart, Customer customer) {
    final salesState = ref.read(salesProvider);

    // Get discount and payment info from sales provider (set during checkout)
    final discount = salesState.discount;
    final isPaid = salesState.isPaid;
    final paymentMethod = salesState.paymentMethod;
    final paidAmount = salesState.paidAmount;

    final finalAmount = PaymentCalculator.calculateTotalAfterDiscount(
      totalAmount: cart.totalAmount,
      discount: discount,
    );
    final actualPaidAmount = isPaid ? finalAmount : paidAmount;

    // Use PaymentCalculator for consistent status determination
    final billStatus = PaymentCalculator.calculatePaymentStatus(
      totalAmount: cart.totalAmount,
      discount: discount,
      paidAmount: actualPaidAmount,
    );

    return Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dateTime: DateTime.now(),
      items: cart.cartItems.keys.toList(),
      quantities: cart.cartItems.map((key, value) => MapEntry(key.id, value)),
      totalAmount: cart.totalAmount,
      discount: discount,
      paidAmount: actualPaidAmount,
      customerName: customer.name,
      customerId: customer.id,
      status: billStatus,
      paymentMethod: paymentMethod ?? 'Cash',
    );
  }

  Future<void> _saveSale(Bill bill, Customer customer) async {
    if (!mounted) return;
    await dbService.saveBill(bill);

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

  // Removed - using PopupMenuButton directly in the UI

  void _showRenameDialog(CartSession cart) {
    final controller = TextEditingController(text: cart.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Cart'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Cart Name',
              hintText: 'Enter cart name',
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: AppButton().primaryButton(
                    height: 35.spMin,
                    text: 'Save',
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        ref
                            .read(multiCartProvider.notifier)
                            .updateCartName(cart.id, controller.text);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final multiCartState = ref.watch(multiCartProvider);
    final activeCart = multiCartState.activeCart;

    // Update tab controller when cart count changes
    final cartCount = multiCartState.carts.length;
    if (_tabController == null || _tabController!.length != cartCount) {
      // Schedule update after this frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTabController(cartCount);
        }
      });
    }

    final headerColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.grey800
            : AppColors.lAppBarColor;

    return Scaffold(
      backgroundColor: headerColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Cart Tabs Header
            Container(
              color: headerColor,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      TablerIcons.plus,
                      size: 20.spMin,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dIconColor
                              : AppColors.lIconColor,
                    ),
                    tooltip: 'New Cart',
                    onPressed: () {
                      ref.read(multiCartProvider.notifier).createNewCart();
                    },
                  ),
                  SizedBox(
                    height: 25.h,
                    child: VerticalDivider(
                      thickness: 2,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.lIconColor
                              : AppColors.dIconColor,
                    ),
                  ),
                  Expanded(
                    child:
                        _tabController != null &&
                                _tabController!.length ==
                                    multiCartState.carts.length
                            ? TabBar(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              labelPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                              ),
                              indicatorPadding: EdgeInsets.only(right: 15.w),
                              tabAlignment: TabAlignment.start,
                              controller: _tabController,
                              isScrollable: true,
                              // Theme-aware colors
                              labelColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.primary
                                      : AppColors.primary,
                              unselectedLabelColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.dIconColor
                                      : AppColors.lIconColor,
                              indicatorColor: AppColors.primary,
                              indicatorSize: TabBarIndicatorSize.label,
                              dividerColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.grey800
                                      : AppColors.grey100,
                              indicatorWeight: 3.0,
                              tabs:
                                  multiCartState.carts.map((cart) {
                                    return Tab(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                            children: [
                                              Icon(
                                                TablerIcons.shopping_cart,
                                                size: 20.spMin,
                                              ),
                                              if (cart.itemCount > 0)
                                                Positioned(
                                                  left: 0,
                                                  child: Container(
                                                    height: 12.spMin,
                                                    width: 12.spMin,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,

                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: customText(
                                                        size: 8.spMin,
                                                        text:
                                                            '${cart.itemCount}',
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(width: 4.w),
                                          smText(text: cart.name),

                                          SizedBox(width: 4.w),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              TablerIcons.dots_vertical,
                                              size: 16.spMin,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Cart options',
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'complete':
                                                  _completeSaleForCart(cart);
                                                  break;
                                                case 'rename':
                                                  _showRenameDialog(cart);
                                                  break;
                                                case 'delete':
                                                  ref
                                                      .read(
                                                        multiCartProvider
                                                            .notifier,
                                                      )
                                                      .deleteCart(cart.id);
                                                  break;
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'complete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          TablerIcons.check,
                                                          size: 18.spMin,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          'Complete Sale',
                                                          style: TextStyle(
                                                            fontSize: 14.spMin,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'rename',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          TablerIcons.edit,
                                                          size: 18.spMin,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          'Rename Cart',
                                                          style: TextStyle(
                                                            fontSize: 14.spMin,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          TablerIcons.trash,
                                                          size: 18.spMin,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          'Delete Cart',
                                                          style: TextStyle(
                                                            fontSize: 14.spMin,
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(0.h),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final isTab =
                        constraints.maxWidth >= 600 &&
                        constraints.maxWidth < 1100;

                    return Scaffold(
                      body: Flex(
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
                            child: buildProductsSection(ref),
                          ),
                          // Show cart section only on tablet and desktop
                          if (!isMobile &&
                              activeCart != null &&
                              activeCart.cartItems.isNotEmpty) ...[
                            SizedBox(width: 2.w),
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.grey800
                                          : AppColors.grey200,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                ),
                                child: SizedBox.expand(
                                  child: buildMultiCartSection(
                                    constraints,
                                    ref,
                                    activeCart,
                                    () => _completeSaleForCart(activeCart),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Show FAB on mobile when active cart has items
                      floatingActionButton:
                          isMobile &&
                                  activeCart != null &&
                                  activeCart.cartItems.isNotEmpty
                              ? FloatingActionButton.extended(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MobileMultiCartPage(
                                            activeCart: activeCart,
                                            onCompleteSale:
                                                () => _completeSaleForCart(
                                                  activeCart,
                                                ),
                                          ),
                                    ),
                                  );
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
                                          '${activeCart.itemCount}',
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
                                  'Rs.${(activeCart.totalAmount - activeCart.discount).toStringAsFixed(0)}',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
