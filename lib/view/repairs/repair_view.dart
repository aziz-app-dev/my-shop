import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../models/repair_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/text_field_widget.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/repair_provider.dart';
import '../../view_models/states/repair_state.dart';
import 'repair_detail_view.dart';
import 'create_repair_view.dart';
import 'widgets/repair_summary_widget.dart';

/// The repair the detail pane is showing on tablet/desktop. Mobile pushes a
/// route instead, so it doesn't use this.
final selectedRepairIdProvider = StateProvider<String?>((ref) => null);

class RepairView extends ConsumerWidget {
  final VoidCallback? openDrawer;
  const RepairView({super.key, this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSplitView =
        AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Repairs',
        context: context,
        automaticallyImplyLeading: openDrawer != null,
        leadingOnTap: openDrawer,
        backIcon: Icons.menu,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(context),
        icon: const Icon(TablerIcons.plus, color: Colors.white),
        label: Text(
          'New Repair',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.spMin,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: useSplitView ? const _SplitLayout() : const _MobileList(),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRepairView()),
    );
  }
}

// ===========================================================================
// MOBILE — single column list, pushes the detail screen on tap.
// ===========================================================================
class _MobileList extends ConsumerWidget {
  const _MobileList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(repairProvider);
    final repairs = state.filteredRepairs;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.spMin, 12.spMin, 16.spMin, 4.spMin),
          child: RepairSummaryCards(state: state),
        ),
        const _SearchAndFilters(),
        Expanded(
          child: _RepairListContent(
            state: state,
            repairs: repairs,
            selectedId: null,
            onSelect:
                (r) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RepairDetailView(repairId: r.id),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// TABLET / DESKTOP — list-detail (MD3 canonical layout).
// ===========================================================================
class _SplitLayout extends ConsumerWidget {
  const _SplitLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(repairProvider);
    final repairs = state.filteredRepairs;
    final isDesktop = AppSizes.isDesktop(context);

    // Keep the selection valid: if the selected repair is filtered out or
    // gone, fall back to the first visible repair.
    final selectedId = ref.watch(selectedRepairIdProvider);
    final effectiveId =
        repairs.any((r) => r.id == selectedId)
            ? selectedId
            : (repairs.isNotEmpty ? repairs.first.id : null);

    // List pane width via .spMin (scales by the smaller axis ratio, ~1.56x on
    // a 1080p desktop — safe). Do NOT use .w here: it scales by the 360 design
    // width (~5.3x on desktop) and would blow the pane up, pushing the detail
    // pane into overflow.
    final listPaneWidth = isDesktop ? 280.spMin : 200.spMin;

    final listPane = Column(
      children: [
        const _SearchAndFilters(),
        Expanded(
          child: _RepairListContent(
            state: state,
            repairs: repairs,
            selectedId: effectiveId,
            onSelect:
                (r) => ref.read(selectedRepairIdProvider.notifier).state = r.id,
          ),
        ),
      ],
    );

    final detailPane = _DetailPane(repairId: effectiveId);

    return Column(
      children: [
        // Summary cards span the full content width above both panes.
        Padding(
          padding: EdgeInsets.fromLTRB(16.spMin, 12.spMin, 16.spMin, 4.spMin),
          child: RepairSummaryCards(state: state),
        ),
        Divider(
          height: 1,
          color: (isDark ? AppColors.grey800 : AppColors.border),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: listPaneWidth, child: listPane),
              VerticalDivider(
                width: 1,
                color: (isDark ? AppColors.grey800 : AppColors.border),
              ),
              Expanded(child: detailPane),
            ],
          ),
        ),
      ],
    );
  }
}

/// The right-hand pane: full repair detail with an overlaid status action,
/// or an empty-state prompt when nothing is selected.
class _DetailPane extends ConsumerWidget {
  final String? repairId;
  const _DetailPane({required this.repairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repair = ref.watch(
      repairProvider.select(
        (s) => s.repairs.where((r) => r.id == repairId).firstOrNull,
      ),
    );

    if (repair == null) {
      return const RepairDetailEmpty(
        message: 'Select a repair to see its details,\nor add a new one.',
      );
    }

    return Column(
      children: [
        // Inline detail toolbar (edit / delete) — the screen-level app bar
        // belongs to the whole Repairs page, so the pane carries its own.
        _DetailToolbar(repair: repair),
        Expanded(child: RepairDetailBody(repair: repair, bottomPadding: 16)),
        RepairStatusBar(repair: repair),
      ],
    );
  }
}

class _DetailToolbar extends ConsumerWidget {
  final Repair repair;
  const _DetailToolbar({required this.repair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.spMin, 12.spMin, 8.spMin, 0),
      child: Row(
        children: [
          Text(
            'Repair Details',
            style: TextStyle(fontSize: 15.spMin, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => openRepairEditor(context, repair),
            icon: AppIcon(
              defaultIcon: TablerIcons.edit,
              win11IconPath: ImageAssets.win11EditPencil,
              size: 18.spMin,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => confirmDeleteRepair(context, ref, repair),
            icon: Icon(
              TablerIcons.trash,
              size: 18.spMin,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Shared: search + status filter chips
// ===========================================================================
class _SearchAndFilters extends ConsumerWidget {
  const _SearchAndFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(repairProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.spMin,
            vertical: 8.spMin,
          ),
          child: CustomTextField(
            hintText: 'Search client, device, brand, serial...',
            isSearch: true,
            prefixIcon: AppIcon(
              defaultIcon: Icons.search,
              win11IconPath: ImageAssets.win11Search,
              size: 16.spMin,
            ),
            onChange: (value) {
              ref.read(repairProvider.notifier).setSearchQuery(value ?? '');
              return null;
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.spMin, 0, 16.spMin, 8.spMin),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: state.showCompleted,
                onTap: () {
                  if (!state.showCompleted) {
                    ref.read(repairProvider.notifier).toggleShowCompleted();
                  }
                },
              ),
              SizedBox(width: 8.spMin),
              _FilterChip(
                label: 'In Repair',
                selected: !state.showCompleted,
                onTap: () {
                  if (state.showCompleted) {
                    ref.read(repairProvider.notifier).toggleShowCompleted();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(20.spMin),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.spMin),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 14.spMin,
            vertical: 7.spMin,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.spMin),
            border: Border.all(
              color:
                  selected
                      ? AppColors.primary
                      : AppColors.border.withValues(alpha: 0.8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.spMin,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? AppColors.primary : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Shared: list content (loading / empty / list of cards)
// ===========================================================================
class _RepairListContent extends StatelessWidget {
  final RepairState state;
  final List<Repair> repairs;
  final String? selectedId;
  final ValueChanged<Repair> onSelect;

  const _RepairListContent({
    required this.state,
    required this.repairs,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (repairs.isEmpty) {
      return _buildEmpty(context);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12.spMin, 4.spMin, 12.spMin, 90.spMin),
      itemCount: repairs.length,
      itemBuilder: (context, index) {
        final repair = repairs[index];
        return RepairCard(
          repair: repair,
          selected: repair.id == selectedId,
          onTap: () => onSelect(repair),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(TablerIcons.tool, size: 56.spMin, color: Colors.grey[400]),
          SizedBox(height: 12.spMin),
          Text(
            'No repair jobs yet',
            style: TextStyle(fontSize: 15.spMin, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.spMin),
          Text(
            'Tap "New Repair" to take an item from a client.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.spMin, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// List card — highlights when it's the selected row in the split view.
// ===========================================================================
class RepairCard extends StatelessWidget {
  final Repair repair;
  final bool selected;
  final VoidCallback onTap;
  const RepairCard({
    super.key,
    required this.repair,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceLine = [
      repair.deviceType,
      repair.brand,
      repair.model,
    ].where((e) => e.trim().isNotEmpty).join(' • ');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 5.spMin),
      elevation: selected ? 0 : 1,
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.spMin),
        side:
            selected
                ? BorderSide(color: AppColors.primary, width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.spMin),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.spMin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(),
              SizedBox(width: 12.spMin),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            repair.clientName,
                            style: TextStyle(
                              fontSize: 14.spMin,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _statusBadge(repair.isCompleted),
                      ],
                    ),
                    if (repair.clientPhone.isNotEmpty)
                      Text(
                        repair.clientPhone,
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (deviceLine.isNotEmpty) ...[
                      SizedBox(height: 4.spMin),
                      Text(
                        deviceLine,
                        style: TextStyle(fontSize: 12.spMin),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (repair.problem.isNotEmpty) ...[
                      SizedBox(height: 4.spMin),
                      Text(
                        repair.problem,
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 6.spMin),
                    Row(
                      children: [
                        if (repair.estimatedCost > 0)
                          Text(
                            'Est: Rs ${repair.estimatedCost.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 11.spMin),
                          ),
                        if (repair.balanceDue > 0) ...[
                          SizedBox(width: 10.spMin),
                          Text(
                            'Due: Rs ${repair.balanceDue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11.spMin,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _thumbnail() {
    final path = repair.imageUrl;
    Widget placeholder = Container(
      width: 54.spMin,
      height: 54.spMin,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.spMin),
      ),
      child: Icon(TablerIcons.device_laptop, color: AppColors.primary),
    );

    if (path == null || path.isEmpty) return placeholder;
    final file = File(path);
    if (!file.existsSync()) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.spMin),
      child: Image.file(
        file,
        width: 54.spMin,
        height: 54.spMin,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _statusBadge(bool completed) {
    final color = completed ? AppColors.success : AppColors.warning;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.spMin, vertical: 3.spMin),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.spMin),
      ),
      child: Text(
        completed ? 'Completed' : 'In Repair',
        style: TextStyle(
          fontSize: 10.spMin,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
