import 'package:flutter/material.dart';

import 'add_product_view.dart';

/// Backwards-compatible entry point.
///
/// The item/service selection used to be a separate page. It now lives at the
/// top of [AddProductScreen] (the two selection cards), so this just opens the
/// unified screen with no type pre-selected.
class ProductTypeSelectionScreen extends StatelessWidget {
  final String? initialName;

  const ProductTypeSelectionScreen({super.key, this.initialName});

  @override
  Widget build(BuildContext context) {
    return AddProductScreen(initialName: initialName);
  }
}
