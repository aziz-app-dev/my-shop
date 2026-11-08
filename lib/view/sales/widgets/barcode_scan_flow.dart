// Shared barcode-scan flow used by the home app bar button, the cart-page
// scan FAB, and previously the (removed) search-row scan buttons.
//
// Extracted so there is ONE camera page and ONE "what happens after a scan"
// behavior instead of duplicated private copies in the two product sections.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/items_model.dart';
import '../../../res/colors/app_color.dart';
import '../../../utils/platform_utils.dart';

/// Opens the camera scanner (mobile only) and returns the scanned string,
/// or null when cancelled / no barcode / unsupported platform.
Future<String?> openBarcodeScanner(BuildContext context) async {
  // mobile_scanner has no desktop implementation; show a hint instead of
  // crashing with a MissingPluginException.
  if (!PlatformUtils.isMobile) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Camera scanning is only available on mobile. On desktop, use a '
          'USB barcode scanner into the search box.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
    return null;
  }

  return Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
  );
}

/// Find product by barcode (case-insensitive exact match).
Product? findProductByBarcode(List<Product> products, String barcode) {
  try {
    return products.firstWhere(
      (p) =>
          p.barcode != null && p.barcode!.toLowerCase() == barcode.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Full scan flow: open the camera, look the barcode up in [products], and
/// on a match call [addToCart]. Out-of-stock and not-found cases show the
/// same dialogs the old search-row scan button used. [onAdded] runs after a
/// successful add (e.g. navigate to the sales page from home).
Future<void> scanAndAddToCart({
  required BuildContext context,
  required List<Product> products,
  required void Function(Product product) addToCart,
  VoidCallback? onAdded,
}) async {
  final result = await openBarcodeScanner(context);
  if (!context.mounted) return;

  if (result == null || result.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan cancelled or no barcode detected'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final product = findProductByBarcode(products, result);
  if (!context.mounted) return;

  if (product != null) {
    // Check stock
    if (!product.isService && product.stock != null && product.stock! <= 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Out of Stock'),
          content: Text('${product.name} is currently out of stock.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    addToCart(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
    onAdded?.call();
  } else {
    // Product not found - show dialog with scanned barcode
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scanned barcode:'),
            SizedBox(height: 4.h),
            SelectableText(result, style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            const Text('Make sure the product has this barcode saved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Barcode Scanner Page — full-screen camera with a scan overlay, torch and
/// camera-flip controls. Pops with the scanned raw value.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController controller;
  bool _isScanning = true;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [
        // Linear (1D) barcodes
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        // 2D barcodes
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;

      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isScanning = false;
          _lastScanned = barcode.rawValue;
        });

        // Show scanned value briefly then return
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context, barcode.rawValue);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return Icon(
                  torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Scan overlay - wider for linear barcodes
          Center(
            child: Container(
              width: 300.w,
              height: 150.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _lastScanned != null ? Colors.green : AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Show scanned value
          if (_lastScanned != null)
            Positioned(
              top: 100.h,
              left: 20.w,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scanned!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.spMin,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _lastScanned!,
                      style: TextStyle(color: Colors.white, fontSize: 14.spMin),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          // Instructions
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _lastScanned != null
                      ? 'Barcode found!'
                      : 'Align barcode within the box',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
