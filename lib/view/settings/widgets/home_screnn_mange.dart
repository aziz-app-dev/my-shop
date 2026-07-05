// Screen Management Section Widget
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../utils/image_picker_helper.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/providers/settings_provider.dart';

// Home Page Settings Page
class HomePageSettingsPage extends ConsumerWidget {
  const HomePageSettingsPage({super.key});

  String _getSectionTitle(String key) {
    switch (key) {
      case 'banner':
        return 'Banner Carousel';
      case 'brands':
        return 'Shop by Brands';
      case 'categories':
        return 'Shop by Categories';
      case 'topSelling':
        return 'Top Selling Products';
      case 'latestItems':
        return 'Latest Added Items';
      case 'latestServices':
        return 'Latest Services';
      case 'lowStock':
        return 'Low Stock Items';
      default:
        return key;
    }
  }

  bool _getSectionVisibility(SettingsState settings, String key) {
    switch (key) {
      case 'banner':
        return settings.showBannerSection;
      case 'brands':
        return settings.showBrandsSection;
      case 'categories':
        return settings.showCategoriesSection;
      case 'topSelling':
        return settings.showTopSellingSection;
      case 'latestItems':
        return settings.showLatestItemsSection;
      case 'latestServices':
        return settings.showLatestServicesSection;
      case 'lowStock':
        return settings.showLowStockSection;
      default:
        return true;
    }
  }

  void _toggleSectionVisibility(WidgetRef ref, String key, bool value) {
    switch (key) {
      case 'banner':
        ref.read(settingsProvider.notifier).setShowBannerSection(value);
        break;
      case 'brands':
        ref.read(settingsProvider.notifier).setShowBrandsSection(value);
        break;
      case 'categories':
        ref.read(settingsProvider.notifier).setShowCategoriesSection(value);
        break;
      case 'topSelling':
        ref.read(settingsProvider.notifier).setShowTopSellingSection(value);
        break;
      case 'latestItems':
        ref.read(settingsProvider.notifier).setShowLatestItemsSection(value);
        break;
      case 'latestServices':
        ref.read(settingsProvider.notifier).setShowLatestServicesSection(value);
        break;
      case 'lowStock':
        ref.read(settingsProvider.notifier).setShowLowStockSection(value);
        break;
    }
  }

  IconData _getSectionIcon(String key) {
    switch (key) {
      case 'banner':
        return Icons.view_carousel;
      case 'brands':
        return Icons.branding_watermark;
      case 'categories':
        return Icons.category;
      case 'topSelling':
        return Icons.trending_up;
      case 'latestItems':
        return Icons.new_releases;
      case 'latestServices':
        return Icons.room_service;
      case 'lowStock':
        return Icons.warning_amber_rounded;
      default:
        return Icons.dashboard;
    }
  }

  String _getSectionWin11Icon(String key) {
    switch (key) {
      case 'banner':
        return ImageAssets.win11ViewCarousel;
      case 'brands':
        return ImageAssets.win11Brand;
      case 'categories':
        return ImageAssets.win11Category;
      case 'topSelling':
        return ImageAssets.win11Graph;
      case 'latestItems':
        return ImageAssets.win11Nuw;
      case 'latestServices':
        return ImageAssets.win11Service2;
      case 'lowStock':
        return ImageAssets.win11LowRisk;
      default:
        return ImageAssets.win11AppsTab;
    }
  }

  Color _getSectionColor(String key) {
    switch (key) {
      case 'banner':
        return Colors.pink;
      case 'brands':
        return AppColors.primary;
      case 'categories':
        return Colors.purple;
      case 'topSelling':
        return Colors.orange;
      case 'latestItems':
        return Colors.blue;
      case 'latestServices':
        return Colors.green;
      case 'lowStock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Home Page Settings',
        context: context,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.md.w,
          vertical: AppSizes.sm.h,
        ),
        children: [
          Card(
            color: AppColors.info.withValues(alpha: 0.2),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                children: [
                  AppIcon(
                    win11IconPath: ImageAssets.win11Info,
                    defaultIcon: Icons.info_outline,
                    color: AppColors.info,
                    size: 25.spMin,
                  ),

                  SizedBox(width: 12.w),
                  Expanded(
                    child: smText(
                      maxLines: 3,
                      text:
                          'Drag and drop sections to reorder. Toggle checkboxes to show/hide.',

                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Reorderable list with drag-and-drop
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: settingsState.sectionOrder.length,
            onReorder: (oldIndex, newIndex) {
              final newOrder = List<String>.from(settingsState.sectionOrder);
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = newOrder.removeAt(oldIndex);
              newOrder.insert(newIndex, item);
              settingsNotifier.setSectionOrder(newOrder);
            },
            itemBuilder: (context, index) {
              final sectionKey = settingsState.sectionOrder[index];
              final isVisible = _getSectionVisibility(
                settingsState,
                sectionKey,
              );
              final color = _getSectionColor(sectionKey);

              return Card(
                key: ValueKey(sectionKey),
                margin: EdgeInsets.only(bottom: 12.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 6.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: AppIcon(
                              win11IconPath: ImageAssets.win11CircledMenu,
                              defaultIcon: Icons.drag_indicator_outlined,
                              color: Colors.grey,
                              size: 30.spMin,
                            ),
                          ),
                          SizedBox(width: 5.h),
                          Container(
                            padding: EdgeInsets.all(6.h),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadiusSm.r,
                              ),
                            ),
                            child: AppIcon(
                              win11IconPath: _getSectionWin11Icon(sectionKey),
                              defaultIcon: _getSectionIcon(sectionKey),
                              color: color,
                              size: 24.spMin,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              smTextBold(text: _getSectionTitle(sectionKey)),
                              xsText(text: isVisible ? 'Visible' : 'Hidden'),
                            ],
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.7.spMin,
                        child: SizedBox(
                          height: 4.h,
                          child: Switch(
                            padding: EdgeInsets.zero,
                            value: isVisible,
                            onChanged: (val) {
                              _toggleSectionVisibility(ref, sectionKey, val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16.h),

          //! Banner Management Section
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.md.h,
                vertical: AppSizes.md.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11ViewCarousel,
                            defaultIcon: Icons.view_carousel,
                            color: AppColors.primary,
                            size: 20.spMin,
                          ),

                          SizedBox(width: 12.w),
                          mdTextBold(text: 'Banner Images'),
                        ],
                      ),
                      InkWell(
                        onTap: () => _pickBannerImage(context, ref),
                        child: AppIcon(
                          win11IconPath: ImageAssets.win11AddImage,
                          defaultIcon: TablerIcons.photo_plus,
                          size: 18.spMin,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Banner images list
                  if (settingsState.bannerImagePaths.isEmpty)
                    Container(
                      padding: EdgeInsets.all(20.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            AppIcon(
                              win11IconPath: ImageAssets.win11NoImage,
                              defaultIcon: Icons.image_not_supported,
                              size: 40.spMin,
                              color: Colors.grey,
                            ),

                            SizedBox(height: 8.h),
                            xsText(
                              text: 'No banner images added',
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: settingsState.bannerImagePaths.length,
                      onReorder: (oldIndex, newIndex) {
                        settingsNotifier.reorderBannerImages(
                          oldIndex,
                          newIndex,
                        );
                      },
                      itemBuilder: (context, index) {
                        final imagePath = settingsState.bannerImagePaths[index];
                        return Container(
                          key: ValueKey(imagePath),
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.dScafoldColor
                                    : AppColors.lScafoldColor),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.textSecondary),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(6.h),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: AppIcon(
                                    win11IconPath: ImageAssets.win11CircledMenu,
                                    defaultIcon: Icons.drag_indicator,
                                    color: Colors.grey,
                                    size: 24.spMin,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                // Image preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: Image.file(
                                    File(imagePath),
                                    width: 80.h,
                                    height: 50.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80.w,
                                        height: 50.h,
                                        color: Colors.grey.shade300,
                                        child: AppIcon(
                                          win11IconPath:
                                              ImageAssets.win11NoImage,
                                          defaultIcon: Icons.broken_image,
                                          color: Colors.grey,
                                          size: 24.spMin,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      smTextBold(text: 'Banner ${index + 1}'),
                                      SizedBox(height: 2.h),
                                      xsText(
                                        text:
                                            imagePath
                                                .split(Platform.pathSeparator)
                                                .last,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    settingsNotifier.removeBannerImage(
                                      imagePath,
                                    );
                                  },
                                  icon: AppIcon(
                                    win11IconPath: ImageAssets.win11RecycleBin,
                                    defaultIcon: Icons.delete_outline,
                                    color: Colors.red,
                                    size: 22.spMin,
                                  ),

                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.h,
                      vertical: 6.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppIcon(
                              win11IconPath: ImageAssets.win11Service,
                              defaultIcon: Icons.settings,
                              color: AppColors.primary,
                              size: 20.spMin,
                            ),

                            SizedBox(width: 12.w),
                            mdTextBold(text: 'Banner Carousel Settings'),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Auto-scroll toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                AppIcon(
                                  win11IconPath: ImageAssets.win11RotateLeft,
                                  defaultIcon: TablerIcons.rotate_clockwise,
                                  size: 18.spMin,
                                ),

                                SizedBox(width: 8.w),
                                smText(text: 'Auto Scroll'),
                              ],
                            ),
                            Transform.scale(
                              scale: 0.8.spMin,
                              child: Switch(
                                value: settingsState.bannerAutoScroll,
                                onChanged: (val) {
                                  settingsNotifier.setBannerAutoScroll(val);
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.h),

                        // Scroll duration slider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIcon(
                                  win11IconPath: ImageAssets.win11DeliveryTime,
                                  defaultIcon: TablerIcons.clock_hour_5,
                                  size: 18.spMin,
                                ),

                                SizedBox(width: 8.w),
                                smText(text: 'Scroll Duration'),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Slider(
                              padding: EdgeInsets.symmetric(vertical: 3.h),
                              value:
                                  settingsState.bannerScrollDuration.toDouble(),
                              min: 2,
                              max: 10,
                              divisions: 8,
                              label: '${settingsState.bannerScrollDuration}s',
                              onChanged:
                                  settingsState.bannerAutoScroll
                                      ? (value) {
                                        settingsNotifier
                                            .setBannerScrollDuration(
                                              value.toInt(),
                                            );
                                      }
                                      : null,
                            ),
                            xsText(
                              text:
                                  'Duration: ${settingsState.bannerScrollDuration} seconds',
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          //! Section Item Count Settings
          Card(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.md.h,
                vertical: AppSizes.md.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppIcon(
                        win11IconPath: ImageAssets.win11Tune,
                        defaultIcon: Icons.tune,
                        color: AppColors.primary,
                        size: 20.spMin,
                      ),

                      SizedBox(width: 12.w),
                      mdTextBold(text: 'Items Per Section'),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Top Selling Products Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11Graph,
                            defaultIcon: Icons.trending_up,
                            size: 18.spMin,
                            color: Colors.orange,
                          ),

                          SizedBox(width: 8.w),
                          smText(text: 'Top Selling Products'),
                        ],
                      ),
                      Slider(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        value: settingsState.topSellingProductsCount.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        label: settingsState.topSellingProductsCount.toString(),
                        onChanged: (value) {
                          settingsNotifier.setTopSellingProductsCount(
                            value.toInt(),
                          );
                        },
                      ),
                      xsText(
                        text:
                            'Showing ${settingsState.topSellingProductsCount} items',
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Latest Items Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11Nuw,
                            defaultIcon: Icons.new_releases,
                            size: 18.spMin,
                            color: Colors.blue,
                          ),

                          SizedBox(width: 8.w),
                          smText(text: 'Latest Added Items'),
                        ],
                      ),
                      Slider(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        value: settingsState.latestItemsCount.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        label: settingsState.latestItemsCount.toString(),
                        onChanged: (value) {
                          settingsNotifier.setLatestItemsCount(value.toInt());
                        },
                      ),
                      xsText(
                        text: 'Showing ${settingsState.latestItemsCount} items',
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Latest Services Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11Service2,
                            defaultIcon: Icons.room_service,
                            size: 18.spMin,
                            color: Colors.green,
                          ),

                          SizedBox(width: 8.w),
                          smText(text: 'Latest Services'),
                        ],
                      ),
                      Slider(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        value: settingsState.latestServicesCount.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        label: settingsState.latestServicesCount.toString(),
                        onChanged: (value) {
                          settingsNotifier.setLatestServicesCount(
                            value.toInt(),
                          );
                        },
                      ),
                      xsText(
                        text:
                            'Showing ${settingsState.latestServicesCount} items',
                        color: Colors.grey,
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Low Stock Items Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11LowRisk,
                            defaultIcon: Icons.warning_amber_rounded,
                            size: 18.spMin,
                            color: Colors.red,
                          ),

                          SizedBox(width: 8.w),
                          smText(text: 'Low Stock Items'),
                        ],
                      ),
                      Slider(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        value: settingsState.lowStockItemsCount.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        label: settingsState.lowStockItemsCount.toString(),
                        onChanged: (value) {
                          settingsNotifier.setLowStockItemsCount(value.toInt());
                        },
                      ),
                      xsText(
                        text:
                            'Showing ${settingsState.lowStockItemsCount} items',
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBannerImage(BuildContext context, WidgetRef ref) async {
    final image = await ImagePickerHelper.pickImageFromGallery();

    if (image != null) {
      ref.read(settingsProvider.notifier).addBannerImage(image.path);
    }
  }
}
