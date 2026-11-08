// Shared barcode-scan flow used by the home app bar button, the cart-page
// scan FABs, and the mobile home action buttons.
//
// Extracted so there is ONE camera page and ONE "what happens after a scan"
// behavior instead of duplicated private copies in the two product sections.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_icon.dart';
import '../../../utils/platform_utils.dart';

/// One scanned product line on the scan page. Repeat scans of the same
/// barcode bump [qty].
class ScannedEntry {
  final Product product;
  int qty;

  ScannedEntry(this.product, [this.qty = 1]);

  String get barcode => product.barcode ?? '';

  double get lineTotal => product.price * qty;
}

/// Opens the camera scanner (mobile only) and returns the collected scan
/// list — empty when cancelled or unsupported platform.
Future<List<ScannedEntry>> openBarcodeScanner(
  BuildContext context, {
  required List<Product> products,
}) async {
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
    return [];
  }

  final result = await Navigator.push<List<ScannedEntry>>(
    context,
    MaterialPageRoute(
      builder: (context) => BarcodeScannerPage(products: products),
    ),
  );
  return result ?? const [];
}

/// Full scan flow: open the persistent scanner page, collect items there
/// (duplicates raise the quantity), and commit everything into the cart
/// via [addToCart] when the user taps "Add to Cart". [onAdded] runs after a
/// successful commit (e.g. navigate to the sales page from home).
Future<void> scanAndFillCart({
  required BuildContext context,
  required List<Product> products,
  required void Function(Product product, int qty) addToCart,
  VoidCallback? onAdded,
}) async {
  final entries = await openBarcodeScanner(context, products: products);
  if (!context.mounted) return;
  if (entries.isEmpty) return;

  var count = 0;
  for (final entry in entries) {
    addToCart(entry.product, entry.qty);
    count += entry.qty;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$count item(s) added to cart'),
      duration: const Duration(seconds: 2),
      backgroundColor: AppColors.primary,
    ),
  );
  onAdded?.call();
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

/// Barcode Scanner Page — continuous scanning session:
///
///  * top ~30%: live camera with the scan overlay (torch / camera flip),
///  * bottom ~70%: the items scanned so far, with quantity controls, line
///    totals and a running total; "Add to Cart" pops with the collected
///    list (empty = cancel).
///
/// Repeat scans of the same barcode increase the quantity instead of
/// stacking another line. Non-matching / out-of-stock scans show an inline
/// event strip rather than interrupting dialogs, so the flow keeps moving.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, required this.products});

  /// All known products to match scans against.
  final List<Product> products;

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController controller;
  String? _lastEvent;
  Color _lastEventColor = Colors.blueGrey;

  /// Collected scan results.
  final List<ScannedEntry> _entries = <ScannedEntry>[];

  /// Debounce: same hardcode within this window is ignored (camera often
  /// sees the same code for a moment).
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastScanCode = '';

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
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Debounce identical consecutive scans (1.5s).
    final now = DateTime.now();
    if (code == _lastScanCode &&
        now.difference(_lastScanTime).inMilliseconds < 1500) {
      return;
    }
    _lastScanCode = code;
    _lastScanTime = now;

    final product = findProductByBarcode(widget.products, code);
    if (!mounted) return;

    if (product == null) {
      setState(() {
        _lastEvent = 'No item with barcode: $code';
        _lastEventColor = Colors.orange;
      });
      return;
    }

    // Stock check (services always pass).
    if (!product.isService && product.stock != null && product.stock! <= 0) {
      setState(() {
        _lastEvent = '${product.name} is out of stock';
        _lastEventColor = Colors.red;
      });
      return;
    }

    // Collect: bump qty on repeats, otherwise a new line.
    setState(() {
      final existing = _entries.where((e) => e.product == product).toList();
      if (existing.isNotEmpty) {
        existing.first.qty += 1;
        _lastEvent = '${product.name} — quantity ${existing.first.qty}';
      } else {
        _entries.add(ScannedEntry(product));
        _lastEvent = '${product.name} added to scan list';
      }
      _lastEventColor = Colors.green;
    });
  }

  void _changeQty(ScannedEntry entry, int delta) {
    setState(() {
      entry.qty += delta;
      if (entry.qty <= 0) _entries.remove(entry);
    });
  }

  int get _totalCount =>
      _entries.fold(0, (sum, entry) => sum + entry.qty);

  double get _totalPrice =>
      _entries.fold(0.0, (sum, entry) => sum + entry.lineTotal);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Same theme appbar the other pages (home, sales, …) use.
      appBar: AppBarWidget.customAppBar(
        context: context,
        title: 'Scan Barcode',
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
      body: Column(
        children: [
          // Camera — top ~35% of the screen. The whole section is the
          // scanner — no viewfinder box overlay.
          Expanded(
            flex: 35,
            child: MobileScanner(controller: controller, onDetect: _onDetect),
          ),
          // Latest scan event
          if (_lastEvent != null)
            Container(
              width: double.infinity,
              color: _lastEventColor,
              padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _lastEvent!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.spMin,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, size: 16.spMin, color: Colors.white),
                    onPressed: () => setState(() => _lastEvent = null),
                  ),
                ],
              ),
            ),
          // Scanned items — remaining ~65% of the screen, on the same
          // scaffold background the other pages (home, sales) use.
          Expanded(
            flex: 65,
            child: Container(
              width: double.infinity,
              color: isDark ? AppColors.dScafoldColor : AppColors.lScafoldColor,
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            defaultIcon: Icons.qr_code_scanner,
                            color: Colors.grey,
                            size: 36.spMin,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Scan items to add them here',
                            style: TextStyle(
                              fontSize: 13.spMin,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(8.spMin),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return _buildEntryTile(entry);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Footer: running total + commit button.
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.all(10.spMin),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.dScafoldColor
                        : AppColors.lScafoldColor,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_entries.length} item type(s) — $_totalCount pcs',
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        'Total: Rs.${_totalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: Text(
                        _entries.isEmpty
                            ? 'Scan items to add to cart'
                            : 'Add $_totalCount item(s) to Cart',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Pop with the collected list — empty list = cancel.
                      onPressed:
                          _entries.isEmpty
                              ? null
                              : () => Navigator.pop(
                                context,
                                List<ScannedEntry>.from(_entries),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(ScannedEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(8.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // Thumbnail
          entry.product.imageUrl != null &&
                  entry.product.imageUrl!.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  File(entry.product.imageUrl!),
                  width: 44.spMin,
                  height: 44.spMin,
                  fit: BoxFit.cover,
                  // Decode at thumbnail size — keeps scanning smooth.
                  cacheWidth: 128,
                  errorBuilder:
                      (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        size: 32.spMin,
                        color: Colors.grey,
                      ),
                ),
              )
              : AppIcon(
                win11IconPath: ImageAssets.win11OpenBox,
                defaultIcon: Icons.inventory_2,
                color: AppColors.primary,
                size: 26.spMin,
              ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Rs.${entry.product.price.toStringAsFixed(0)} × ${entry.qty} = Rs.${entry.lineTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.spMin,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          // qty stepper
          Row(
            children: [
              _qtyButton(Icons.remove_rounded, () => _changeQty(entry, -1)),
              Container(
                constraints: BoxConstraints(minWidth: 28.w),
                alignment: Alignment.center,
                child: Text(
                  '${entry.qty}',
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _qtyButton(Icons.add_rounded, () => _changeQty(entry, 1)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20.spMin,
                  color: Colors.red,
                ),
                tooltip: 'Remove',
                onPressed: () => setState(() => _entries.remove(entry)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.all(6.h),
        decoration: BoxDecoration(
          color: AppColors.primaryLight4,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 18.spMin, color: Colors.black87),
      ),
    );
  }
}
