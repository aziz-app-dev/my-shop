import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../view_models/providers/bills_provider.dart';

class SearchBarWidget extends ConsumerWidget {
  final VoidCallback onFilterTap;
  final bool hasActiveFilter;

  const SearchBarWidget({
    super.key,
    required this.onFilterTap,
    required this.hasActiveFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsNotifier = ref.read(billsProvider.notifier);
    final searchController = billsNotifier.searchController;

    // Watch filteredBills to rebuild UI when search updates
    ref.watch(billsProvider.select((state) => state.filteredBills));

    return Padding(
      padding: EdgeInsets.only(left: 16.spMin, right: 16.spMin, top: 16.spMin),
      child: CustomTextField(
        controller: searchController,
        hintText: 'Search with key words...',
        prefixIcon: const AppIcon(
          defaultIcon: Icons.search,
          win11IconPath: ImageAssets.win11Search,
        ),
        filled: true,
        isDense: true,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (searchController.text.isNotEmpty)
              IconButton(
                padding: EdgeInsets.zero,
                icon: AppIcon(
                  defaultIcon: Icons.clear,
                  win11IconPath: ImageAssets.win11Cancel,
                  size: 18.spMin,
                ),
                onPressed: () {
                  searchController.clear();
                  billsNotifier.filterAndSortBills();
                },
              ),
            IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Filters',
              icon: Icon(
                hasActiveFilter
                    ? TablerIcons.filter_filled
                    : TablerIcons.filter,
                size: 20.spMin,
                color: hasActiveFilter
                    ? AppColors.primary
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dIconColor
                        : AppColors.lIconColor),
              ),
              onPressed: onFilterTap,
            ),
            SizedBox(width: 4.spMin),
          ],
        ),
        onChange: (value) {
          billsNotifier.filterAndSortBills();
          return null;
        },
      ),
    );
  }
}
