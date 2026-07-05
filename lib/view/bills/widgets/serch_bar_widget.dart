import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../view_models/providers/bills_provider.dart';

class SearchBarWidget extends ConsumerWidget {
  final VoidCallback onFilterToggle;
  final bool isFilterVisible;

  const SearchBarWidget({
    super.key,
    required this.onFilterToggle,
    required this.isFilterVisible,
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
            // IconButton(
            //   padding: EdgeInsets.zero,
            //   icon: Icon(
            //     TablerIcons.filter_cog,
            //     size: 18.spMin,
            //     color:
            //         isFilterVisible
            //             ? AppColors.primary
            //             : (Theme.of(context).brightness == Brightness.dark
            //                 ? AppColors.dIconColor
            //                 : AppColors.lIconColor),
            //   ),
            //   onPressed: onFilterToggle,
            // ),
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
