// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:open_file/open_file.dart';
import '../../models/shopping_list_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../view_models/providers/shopping_list_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../../view_models/services/database/database_services.dart';
import '../product_details/product_details_view.dart';
import 'shopping_list_search_view.dart';
import 'widgets/shopping_list_pdf_generator.dart';

class ShoppingListView extends ConsumerStatefulWidget {
  const ShoppingListView({super.key});

  @override
  ConsumerState<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends ConsumerState<ShoppingListView> {
  @override
  Widget build(BuildContext context) {
    final shoppingListState = ref.watch(shoppingListProvider);
    final shoppingListNotifier = ref.read(shoppingListProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        context: context,
        title: shoppingListState.currentListName, // Show current list name
        actions: [
          // More menu with list management
          PopupMenuButton<String>(
            color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'create') {
                _showCreateListDialog(context, shoppingListNotifier);
              } else if (value == 'duplicate') {
                _showDuplicateListDialog(context, shoppingListNotifier);
              } else if (value == 'download_pdf') {
                await _generateAndDownloadPDF();
              } else if (value == 'select_all') {
                shoppingListNotifier.selectAll();
              } else if (value == 'deselect_all') {
                shoppingListNotifier.deselectAll();
              } else if (value.startsWith('select_')) {
                final listId = value.substring(7);
                shoppingListNotifier.selectList(listId);
              } else if (value.startsWith('delete_')) {
                final listId = value.substring(7);
                _showDeleteConfirmation(context, listId, shoppingListNotifier);
              }
            },
            itemBuilder:
                (context) => [
                  // Select All / Deselect All options
                  if (shoppingListState.unshoppedItems.isNotEmpty) ...[
                    if (shoppingListState.selectedItemIds.isEmpty)
                      PopupMenuItem(
                        value: 'select_all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 18.spMin,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            smText(text: 'Select All'),
                          ],
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: 'deselect_all',
                        child: Row(
                          children: [
                            Icon(
                              Icons.clear_all,
                              size: 18.spMin,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            smText(text: 'Deselect All'),
                          ],
                        ),
                      ),
                    const PopupMenuDivider(),
                  ],
                  PopupMenuItem(
                    value: 'create',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18.spMin, color: Colors.blue),
                        SizedBox(width: 8),
                        smText(text: 'Create New List'),
                      ],
                    ),
                  ),
                  if (shoppingListState.currentListId != null)
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18.spMin, color: Colors.green),
                          SizedBox(width: 8),
                          smText(text: 'Duplicate List'),
                        ],
                      ),
                    ),
                  if (shoppingListState.unshoppedItems.isNotEmpty)
                    PopupMenuItem(
                      value: 'download_pdf',
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 18.spMin,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          smText(text: 'Download PDF'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),

                  // Show all lists with current one highlighted
                  ...shoppingListState.lists.map((list) {
                    final isCurrent =
                        list.id == shoppingListState.currentListId;
                    return PopupMenuItem(
                      value: 'select_${list.id}',
                      enabled: !isCurrent,
                      child: Row(
                        children: [
                          Icon(
                            isCurrent
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 18.spMin,
                            color: isCurrent ? AppColors.primary : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: customText(
                              text: list.name,
                              size: 12.spMin,
                              color: isCurrent ? AppColors.primary : null,
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          if (shoppingListState.lists.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 18.spMin,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(
                                  context,
                                  list.id,
                                  shoppingListNotifier,
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                ],
          ),
        ],
      ),
      body:
          shoppingListState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : shoppingListState.error != null
              ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.md.h,
                    vertical: AppSizes.md.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16.h),
                      Text('Error: ${shoppingListState.error}'),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed:
                            () => shoppingListNotifier.loadShoppingList(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  // Stats Row
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.md.h,
                      vertical: AppSizes.md.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total',
                          shoppingListState.totalItems.toString(),
                          AppColors.primary,
                          isDark,
                        ),
                        _buildStatCard(
                          'Pending',
                          shoppingListState.unshoppedCount.toString(),
                          Colors.orange,
                          isDark,
                        ),
                        _buildStatCard(
                          'Shopped',
                          shoppingListState.shoppedCount.toString(),
                          Colors.green,
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Items Grid
                  Expanded(
                    child:
                        shoppingListState.filteredItems.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 64.spMin,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16.h),
                                  smText(
                                    text:
                                        shoppingListState.searchQuery.isEmpty
                                            ? 'No items in shopping list'
                                            : 'No items found',
                                  ),
                                ],
                              ),
                            )
                            : LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount;
                                double childAspectRatio;

                                if (AppSizes.isMobile(context)) {
                                  // Mobile
                                  crossAxisCount = 3;
                                  childAspectRatio = 0.85.spMin;
                                } else if (AppSizes.isTablet(context)) {
                                  // Tablet
                                  crossAxisCount = 5;
                                  childAspectRatio = 0.85.spMin;
                                } else {
                                  // Desktop
                                  crossAxisCount = 8;
                                  childAspectRatio = 0.85.spMin;
                                }

                                return GridView.builder(
                                  padding: EdgeInsets.all(12.w),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: childAspectRatio,
                                        crossAxisSpacing: 6.h,
                                        mainAxisSpacing: 12.h,
                                      ),
                                  itemCount:
                                      shoppingListState.filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        shoppingListState.filteredItems[index];
                                    final isSelected = shoppingListState
                                        .selectedItemIds
                                        .contains(item.id);

                                    return _buildShoppingItemCard(
                                      item,
                                      isSelected,
                                      isDark,
                                      shoppingListNotifier,
                                    );
                                  },
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Mark as Shopped Button
          if (shoppingListState.selectedItemIds.isNotEmpty)
            FloatingActionButton.extended(
              onPressed: () async {
                await shoppingListNotifier.markSelectedAsShopped();
                if (context.mounted) {
                  AppFlushbar.success(
                    context,
                    message: 'Items marked as shopped and stock updated',
                  );
                }
              },
              label: Text(
                'Mark ${shoppingListState.selectedItemIds.length} as Shopped',
              ),
              icon: const Icon(Icons.check_circle),
              backgroundColor: Colors.green,
              heroTag: 'markShopped',
            ),
          SizedBox(height: 12.h),

          // Add Item Button - Navigate to Search View
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingListSearchView(),
                ),
              );
            },
            label: const Text('Add Items'),
            icon: const Icon(Icons.add),
            heroTag: 'addItem',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.spMin,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(fontSize: 10.spMin)),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPDF() async {
    final shoppingListState = ref.read(shoppingListProvider);
    final currentList = shoppingListState.currentList;

    if (currentList == null) {
      if (mounted) {
        AppFlushbar.error(context, message: 'No shopping list selected');
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        AppFlushbar.info(
          context,
          message: 'Generating PDF...',
          duration: const Duration(seconds: 2),
        );
      }

      // Load user data directly from database
      final dbService = DatabaseService();
      final users = await dbService.getUsers();
      final String shopName = users.isNotEmpty ? users.first.shopName : 'My Shop';
      final String? ownerName =
          users.isNotEmpty ? users.first.ownerName : null;

      // Generate PDF
      final pdfGenerator = ShoppingListPDFGenerator(
        shoppingList: currentList,
        items: shoppingListState.items,
        shopName: shopName,
        ownerName: ownerName,
      );
      final pdf = pdfGenerator.generatePDF();

      // Get directory path from settings
      final settingsState = ref.read(settingsProvider);
      String directoryPath = settingsState.directoryPath;

      // If no custom path is set, use default
      if (directoryPath.isEmpty) {
        final dbService = DatabaseService();
        directoryPath = await dbService.getCurrentHivePath();
      }

      // Create shopping_list folder inside the configured directory
      final directory = Directory('$directoryPath/shopping_list');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          'shopping_list_${currentList.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$directoryPath/shopping_list/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        AppFlushbar.success(
          context,
          message: 'PDF saved successfully',
          actionText: 'Open',
          onActionPressed: () async {
            await OpenFile.open(file.path);
          },
        );
      }

      // Automatically open the PDF
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        AppFlushbar.error(context, message: 'Error generating PDF: $e');
      }
    }
  }

  Widget _buildShoppingItemCard(
    ShoppingListItem item,
    bool isSelected,
    bool isDark,
    ShoppingListNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () {
        if (!item.isShopped) {
          notifier.toggleItemSelection(item.id);
        }
      },
      onLongPress: () {
        _showItemDropdownMenu(context, item, notifier);
      },
      onSecondaryTapDown: (details) {
        _showItemDropdownMenu(context, item, notifier, details.globalPosition);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : (item.isShopped ? Colors.green : AppColors.grey300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  // Product Image
                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppSizes.borderRadiusMd - 1.r),
                        topRight: Radius.circular(
                          AppSizes.borderRadiusMd - 1.r,
                        ),
                      ),
                    ),
                    child:
                        item.productImageUrl != null &&
                                item.productImageUrl!.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                  AppSizes.borderRadiusMd - 1.r,
                                ),
                                topRight: Radius.circular(
                                  AppSizes.borderRadiusMd - 1.r,
                                ),
                              ),
                              child: Image.file(
                                height: double.infinity,
                                width: double.infinity,
                                File(item.productImageUrl!),
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, trace) => Center(
                                      child: Icon(
                                        Icons.shopping_bag,
                                        size: 40.spMin,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            )
                            : Center(
                              child: Icon(
                                Icons.shopping_bag,
                                size: 40.spMin,
                                color: Colors.grey,
                              ),
                            ),
                  ),

                  // // Checkbox Overlay
                  // if (!item.isShopped)
                  //   Positioned(
                  //     top: 8.h,
                  //     right: 8.w,
                  //     child: Container(
                  //       padding: EdgeInsets.all(4.w),
                  //       decoration: BoxDecoration(
                  //         color: Colors.white,
                  //         shape: BoxShape.circle,
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: Colors.black.withValues(alpha: 0.2),
                  //             blurRadius: 4,
                  //           ),
                  //         ],
                  //       ),
                  //       child: Icon(
                  //         isSelected
                  //             ? Icons.check_box
                  //             : Icons.check_box_outline_blank,
                  //         color: isSelected ? AppColors.primary : Colors.grey,
                  //         size: 24.spMin,
                  //       ),
                  //     ),
                  //   ),

                  // Shopped Badge
                  if (item.isShopped)
                    Positioned(
                      top: 4.spMin,
                      right: 4.spMin,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.h,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusMd.r,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 12.spMin,
                            ),
                            SizedBox(width: 4.h),
                            Text(
                              'Shopped',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.spMin,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            //! Info Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.spMin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smTextBold(text: item.productName, maxLines: 1),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: customText(
                          size: 10.spMin,
                          text: 'Qty: ${item.quantityNeeded}',
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.brand != null) ...[
                        SizedBox(height: 2.h),
                        customText(
                          size: 9.spMin,
                          text: item.brand!,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showItemDropdownMenu(
    BuildContext context,
    ShoppingListItem item,
    ShoppingListNotifier notifier, [
    Offset? position,
  ]) async {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    final value = await showMenu<String>(
      surfaceTintColor:
          (Theme.of(context).brightness == Brightness.dark
              ? AppColors.dCardColor
              : AppColors.lCardColor),
      color:
          (Theme.of(context).brightness == Brightness.dark
              ? AppColors.dCardColor
              : AppColors.lCardColor),

      context: context,
      position:
          position != null
              ? RelativeRect.fromLTRB(
                position.dx,
                position.dy,
                overlay?.size.width ?? position.dx,
                overlay?.size.height ?? position.dy,
              )
              : RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        PopupMenuItem<String>(
          value: 'open_details',
          child: Row(children: [smText(text: 'Open Details')]),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [smText(text: 'Edit Quantity')]),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(children: [smText(text: 'Delete Item')]),
        ),
      ],
    );

    if (!mounted) return;

    if (value == 'open_details') {
      // Load the product from database and navigate to details
      try {
        final dbService = DatabaseService();
        final products = await dbService.getProducts();
        final product =
            products.where((p) => p.id == item.productId).firstOrNull;

        if (!mounted) return;

        if (product != null) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        } else {
          if (!mounted) return;
          AppFlushbar.error(context, message: 'Product not found');
        }
      } catch (e) {
        if (!mounted) return;
        AppFlushbar.error(context, message: 'Error loading product: $e');
      }
    } else if (value == 'edit') {
      _showEditQuantityDialog(context, item, notifier);
    } else if (value == 'delete') {
      notifier.deleteItem(item.id);
      if (mounted) {
        AppFlushbar.info(context, message: 'Item deleted');
      }
    }
  }

  void _showEditQuantityDialog(
    BuildContext context,
    ShoppingListItem item,
    ShoppingListNotifier notifier,
  ) {
    final controller = TextEditingController(
      text: item.quantityNeeded.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Quantity'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newQuantity = int.tryParse(controller.text) ?? 1;
                  notifier.updateQuantity(item.id, newQuantity);
                  Navigator.pop(context);
                  AppFlushbar.success(context, message: 'Quantity updated');
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showCreateListDialog(
    BuildContext context,
    ShoppingListNotifier notifier,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New List'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    await notifier.createNewList(controller.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppFlushbar.success(
                        context,
                        message: 'List "${controller.text}" created',
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  void _showDuplicateListDialog(
    BuildContext context,
    ShoppingListNotifier notifier,
  ) {
    final currentList = ref.read(shoppingListProvider).currentList;
    if (currentList == null) return;

    final controller = TextEditingController(
      text: '${currentList.name} (Copy)',
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Duplicate List'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New List Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    await notifier.duplicateList(
                      currentList.id,
                      controller.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppFlushbar.success(
                        context,
                        message: 'List duplicated as "${controller.text}"',
                      );
                    }
                  }
                },
                child: const Text('Duplicate'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String listId,
    ShoppingListNotifier notifier,
  ) {
    final list = ref
        .read(shoppingListProvider)
        .lists
        .firstWhere((l) => l.id == listId);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete List'),
            content: Text(
              'Are you sure you want to delete "${list.name}"? This will also delete all items in the list.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await notifier.deleteList(listId);
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFlushbar.success(context, message: 'List deleted');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
