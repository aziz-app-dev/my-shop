// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/category_model.dart';
import '../../utils/image_picker_helper.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/services/database/database_services.dart';

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final dbService = DatabaseService();
  return await dbService.getCategories();
});

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddCategoryDialog({Category? category}) {
    final TextEditingController controller = TextEditingController(
      text: category?.name ?? '',
    );
    final isEdit = category != null;
    final ValueNotifier<File?> selectedImageNotifier = ValueNotifier<File?>(
      null,
    );
    final ValueNotifier<String?> existingImageUrlNotifier =
        ValueNotifier<String?>(category?.imageUrl);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              isEdit ? 'Edit Category' : 'Add New Category',
              style: TextStyle(fontSize: 18.spMin),
            ),
            content: SizedBox(
              width: 280.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker
                    ValueListenableBuilder<File?>(
                      valueListenable: selectedImageNotifier,
                      builder: (context, selectedImage, _) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: existingImageUrlNotifier,
                          builder: (context, existingImageUrl, _) {
                            return GestureDetector(
                              onTap: () async {
                                final image =
                                    await ImagePickerHelper.pickImageFromGallery();
                                if (image != null) {
                                  selectedImageNotifier.value = image;
                                  existingImageUrlNotifier.value = null;
                                }
                              },
                              child: Container(
                                height: 120.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child:
                                      selectedImage != null
                                          ? Stack(
                                            children: [
                                              SizedBox(
                                                height: 120.h,
                                                child: Image.file(
                                                  selectedImage,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4.h,
                                                right: 4.w,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                    size: 24.spMin,
                                                  ),
                                                  onPressed: () {
                                                    selectedImageNotifier
                                                        .value = null;
                                                    existingImageUrlNotifier
                                                            .value =
                                                        category?.imageUrl;
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                          : existingImageUrl != null
                                          ? Stack(
                                            children: [
                                              Image.file(
                                                File(existingImageUrl),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                              Positioned(
                                                top: 4.h,
                                                right: 4.w,
                                                child: IconButton(
                                                  icon: Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                    size: 24.spMin,
                                                  ),
                                                  onPressed: () {
                                                    existingImageUrlNotifier
                                                        .value = null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                          : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  size: 40.spMin,
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.7),
                                                ),
                                                SizedBox(height: 8.h),
                                                smText(
                                                  text:
                                                      'Tap to add category icon',
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 16.h),
                    // Category Name TextField
                    CustomTextField(
                      controller: controller,
                      label: 'Category Name',
                      hintText: 'Enter category name',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppButton().primaryButton(
                      height: 35.spMin,
                      text: isEdit ? 'Update' : 'Add',
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) {
                          AppFlushbar.error(
                            context,
                            message: 'Category name cannot be empty',
                          );
                          return;
                        }

                        final imageUrl =
                            selectedImageNotifier.value?.path ??
                            existingImageUrlNotifier.value;

                        if (isEdit) {
                          final updatedCategory = category.copyWith(
                            name: controller.text.trim(),
                            imageUrl: imageUrl,
                            updatedAt: DateTime.now(),
                          );
                          await _dbService.updateCategory(updatedCategory);
                        } else {
                          final newCategory = Category(
                            id:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                            name: controller.text.trim(),
                            imageUrl: imageUrl,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          await _dbService.addCategory(newCategory);
                        }

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ref.invalidate(categoriesProvider);
                          AppFlushbar.success(
                            context,
                            message:
                                isEdit
                                    ? 'Category updated successfully'
                                    : 'Category added successfully',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: mdTextBold(text: 'Delete Category'),
            content: mdText(
              text: 'Are you sure you want to delete "${category.name}"?',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppButton().primaryButton(
                      color: AppColors.error,
                      height: 35.spMin,
                      text: 'Delete',
                      onPressed: () async {
                        await _dbService.deleteCategory(category.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ref.invalidate(categoriesProvider);
                          AppFlushbar.success(
                            context,
                            message: 'Category deleted successfully',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Category Management',
        context: context,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80.spMin,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No categories added yet',
                    style: TextStyle(fontSize: 16.spMin, color: Colors.grey),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Tap the + button to add a category',
                    style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.horizontalPaddingSm.w,
              vertical: AppSizes.verticalPaddingSm.h,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.md.h,
                    vertical: 8.h,
                  ),

                  leading:
                      category.imageUrl != null
                          ? SizedBox(
                            width: 56.h,
                            height: 56.h,
                            child: Image.file(
                              File(category.imageUrl!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.branding_watermark,
                                  color: AppColors.primary,
                                  size: 24.spMin,
                                );
                              },
                            ),
                          )
                          : Container(
                            width: 56.h,
                            height: 56.h,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.category,
                              color: AppColors.primary,
                              size: 24.spMin,
                            ),
                          ),
                  title: mdTextBold(text: category.name),

                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                      size: 22.spMin,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddCategoryDialog(category: category);
                      } else if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: AppColors.primary,
                                  size: 18.spMin,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Edit',
                                  style: TextStyle(fontSize: 14.spMin),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18.spMin,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Delete',
                                  style: TextStyle(fontSize: 14.spMin),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Text(
                'Error: $error',
                style: TextStyle(fontSize: 14.spMin, color: Colors.red),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
