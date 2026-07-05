// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/brand_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_icon.dart';
import '../../utils/image_picker_helper.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../view_models/services/database/database_services.dart';
import '../../view_models/services/cloudinary/cloudinary_service.dart';

final brandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getBrands();
});

class BrandManagementScreen extends ConsumerStatefulWidget {
  const BrandManagementScreen({super.key});

  @override
  ConsumerState<BrandManagementScreen> createState() =>
      _BrandManagementScreenState();
}

class _BrandManagementScreenState extends ConsumerState<BrandManagementScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showAddBrandDialog({Brand? brand}) {
    final TextEditingController controller = TextEditingController(
      text: brand?.name ?? '',
    );
    final isEdit = brand != null;
    final ValueNotifier<File?> selectedImageNotifier = ValueNotifier<File?>(
      null,
    );
    final ValueNotifier<String?> existingImageUrlNotifier =
        ValueNotifier<String?>(brand?.imageUrl);
    final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => ValueListenableBuilder<bool>(
            valueListenable: isLoadingNotifier,
            builder: (context, isLoading, _) {
              return AlertDialog(
                title: Text(
                  isEdit ? 'Edit Brand' : 'Add New Brand',
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
                                  onTap:
                                      isLoading
                                          ? null
                                          : () async {
                                            final image =
                                                await ImagePickerHelper.pickImageFromGallery();
                                            if (image != null) {
                                              selectedImageNotifier.value =
                                                  image;
                                              existingImageUrlNotifier.value =
                                                  null;
                                            }
                                          },
                                  child: Container(
                                    height: 120.h,
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
                                      child: Stack(
                                        children: [
                                          // Image content
                                          if (selectedImage != null)
                                            Image.file(
                                              selectedImage,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          else if (existingImageUrl != null)
                                            Image.file(
                                              File(existingImageUrl),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          else
                                            Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  AppIcon(
                                                    defaultIcon:
                                                        Icons
                                                            .add_photo_alternate_outlined,
                                                    win11IconPath:
                                                        ImageAssets
                                                            .win11AddImage,
                                                    size: 40.spMin,
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.7),
                                                  ),
                                                  SizedBox(height: 8.h),
                                                  smText(
                                                    text:
                                                        'Tap to add brand logo',
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // Loading overlay
                                          if (isLoading &&
                                              selectedImage != null)
                                            Container(
                                              color: Colors.black54,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 30.spMin,
                                                      height: 30.spMin,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 3,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    smText(
                                                      text: 'Uploading...',
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          // Cancel button (only when not loading)
                                          if (!isLoading &&
                                              (selectedImage != null ||
                                                  existingImageUrl != null))
                                            Positioned(
                                              top: 4.h,
                                              right: 4.w,
                                              child: IconButton(
                                                icon: AppIcon(
                                                  defaultIcon: Icons.cancel,
                                                  win11IconPath:
                                                      ImageAssets.win11Cancel,
                                                  color: Colors.red,
                                                  size: 24.spMin,
                                                ),
                                                onPressed: () {
                                                  if (selectedImage != null) {
                                                    selectedImageNotifier
                                                        .value = null;
                                                    existingImageUrlNotifier
                                                            .value =
                                                        brand?.imageUrl;
                                                  } else {
                                                    existingImageUrlNotifier
                                                        .value = null;
                                                  }
                                                },
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16.h),

                        CustomTextField(
                          controller: controller,
                          enabled: !isLoading,
                          label: 'Brand Name',
                          hintText: 'Enter brand name',
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
                          onPressed:
                              isLoading
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14.spMin),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AppButton().primaryButton(
                          height: 35.spMin,
                          text:
                              isLoading
                                  ? 'Saving...'
                                  : isEdit
                                  ? 'Update'
                                  : 'Add',
                          onPressed:
                              isLoading
                                  ? () {}
                                  : () async {
                                    if (controller.text.trim().isEmpty) {
                                      AppFlushbar.error(
                                        context,
                                        message: 'Brand name cannot be empty',
                                      );
                                      return;
                                    }

                                    isLoadingNotifier.value = true;

                                    try {
                                      String? imageUrl =
                                          existingImageUrlNotifier.value;

                                      // Upload to Cloudinary if new image selected
                                      if (selectedImageNotifier.value != null) {
                                        final cloudinaryService =
                                            CloudinaryService();
                                        if (cloudinaryService.isConfigured) {
                                          final uploadResult =
                                              await cloudinaryService
                                                  .uploadImage(
                                                    selectedImageNotifier
                                                        .value!,
                                                    folder: 'brands',
                                                  );
                                          if (uploadResult.success &&
                                              uploadResult.url != null) {
                                            imageUrl = uploadResult.url;
                                          } else {
                                            // Fallback to local path if upload fails
                                            imageUrl =
                                                selectedImageNotifier
                                                    .value!
                                                    .path;
                                          }
                                        } else {
                                          // Use local path if Cloudinary not configured
                                          imageUrl =
                                              selectedImageNotifier.value!.path;
                                        }
                                      }

                                      final now = DateTime.now();
                                      if (isEdit) {
                                        // Update existing brand
                                        final updatedBrand = Brand(
                                          id: brand.id,
                                          name: controller.text.trim(),
                                          imageUrl: imageUrl,
                                          createdAt: brand.createdAt ?? now,
                                          updatedAt: now,
                                        );
                                        await _dbService.updateBrand(
                                          updatedBrand,
                                        );
                                      } else {
                                        // Add new brand
                                        final newBrand = Brand(
                                          id:
                                              DateTime.now()
                                                  .millisecondsSinceEpoch
                                                  .toString(),
                                          name: controller.text.trim(),
                                          imageUrl: imageUrl,
                                          createdAt: now,
                                          updatedAt: now,
                                        );
                                        await _dbService.addBrand(newBrand);
                                      }

                                      isLoadingNotifier.value = false;

                                      if (mounted) {
                                        Navigator.pop(dialogContext);
                                        ref.invalidate(brandsProvider);
                                        AppFlushbar.success(
                                          context,
                                          message:
                                              isEdit
                                                  ? 'Brand updated successfully'
                                                  : 'Brand added successfully',
                                        );
                                      }
                                    } catch (e) {
                                      isLoadingNotifier.value = false;
                                      AppFlushbar.error(
                                        context,
                                        message: 'Error: ${e.toString()}',
                                      );
                                    }
                                  },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }

  void _deleteBrand(Brand brand) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Brand', style: TextStyle(fontSize: 18.spMin)),
            content: Text(
              'Are you sure you want to delete "${brand.name}"?',
              style: TextStyle(fontSize: 14.spMin),
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
                      text: "Delete",
                      onPressed: () async {
                        await _dbService.deleteBrand(brand.id);
                        if (mounted) {
                          Navigator.pop(context);
                          ref.invalidate(brandsProvider);
                          AppFlushbar.success(
                            context,
                            message: 'Brand deleted successfully',
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
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Brand Management',
        context: context,
      ),
      body: brandsAsync.when(
        data: (brands) {
          if (brands.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    defaultIcon: Icons.category_outlined,
                    win11IconPath: ImageAssets.win11Category,
                    size: 80.spMin,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  mdTextBold(text: 'No brands added yet'),
                  SizedBox(height: 8.h),
                  smText(text: 'Tap the + button to add a brand'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.md.h,
              vertical: AppSizes.sm.h,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
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
                      brand.imageUrl != null
                          ? SizedBox(
                            width: 56.h,
                            height: 56.h,
                            child: Image.file(
                              File(brand.imageUrl!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return AppIcon(
                                  defaultIcon: Icons.branding_watermark,
                                  win11IconPath: ImageAssets.win11Brand,
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
                            child: AppIcon(
                              defaultIcon: Icons.branding_watermark,
                              win11IconPath: ImageAssets.win11Brand,
                              color: AppColors.primary,
                              size: 24.spMin,
                            ),
                          ),
                  title: mdTextBold(text: brand.name),

                  trailing: PopupMenuButton<String>(
                    icon: AppIcon(
                      defaultIcon: Icons.more_vert,
                      win11IconPath: ImageAssets.win11MenuVertical,
                      color: Colors.grey,
                      size: 22.spMin,
                      imgSize: 26.spMin,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddBrandDialog(brand: brand);
                      } else if (value == 'delete') {
                        _deleteBrand(brand);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                AppIcon(
                                  defaultIcon: Icons.edit,
                                  win11IconPath: ImageAssets.win11EditPencil,
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
                                AppIcon(
                                  defaultIcon: Icons.delete,
                                  win11IconPath: ImageAssets.win11RecycleBin,
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
        onPressed: _showAddBrandDialog,
        child: AppIcon(
          defaultIcon: Icons.add,
          win11IconPath: ImageAssets.win11Add,
        ),
      ),
    );
  }
}
