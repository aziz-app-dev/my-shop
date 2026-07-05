import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/repair_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_icon.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/repair_provider.dart';
import 'create_repair_view.dart';

/// Full-screen detail view for a single repair job (used on mobile, pushed as
/// a route). On larger screens the same content renders inline via
/// [RepairDetailBody] inside the list-detail layout — see [RepairView].
///
/// Separates *viewing* a repair from *editing* it (which lives in
/// [CreateRepairView]). Reads the live repair from [repairProvider] by id so
/// the screen reflects edits and the completed-toggle without manual refresh.
class RepairDetailView extends ConsumerWidget {
  final String repairId;
  const RepairDetailView({super.key, required this.repairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live list and resolve our repair by id. If it was deleted
    // (e.g. from another surface), gracefully pop back.
    final repair = ref.watch(
      repairProvider.select(
        (s) => s.repairs.where((r) => r.id == repairId).firstOrNull,
      ),
    );

    if (repair == null) {
      return Scaffold(
        appBar: AppBarWidget.customAppBar(title: 'Repair', context: context),
        body: const RepairDetailEmpty(
          message: 'This repair is no longer available.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Repair Details',
        context: context,
        actions: [
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
            onPressed:
                () => confirmDeleteRepair(
                  context,
                  ref,
                  repair,
                  popScreenAfter: true,
                ),
            icon: Icon(
              TablerIcons.trash,
              size: 18.spMin,
              color: AppColors.error,
            ),
          ),
        ],
      ),
      body: RepairDetailBody(repair: repair),
      bottomNavigationBar: RepairStatusBar(repair: repair),
    );
  }
}

/// The scrollable detail content for a single repair, reusable both as the
/// body of [RepairDetailView] (mobile) and inline in the list-detail pane
/// (tablet/desktop).
class RepairDetailBody extends StatelessWidget {
  final Repair repair;

  /// Extra bottom padding so content clears an overlaid action bar when the
  /// detail is shown inline (the pane has no Scaffold bottomNavigationBar).
  final double bottomPadding;
  const RepairDetailBody({
    super.key,
    required this.repair,
    this.bottomPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Two-column info grid on wide panes; single column when the pane is tight.
    final wide = MediaQuery.of(context).size.width >= 900;

    final infoSections = <Widget>[
      _DeviceSection(repair: repair, isDark: isDark),
      _ProblemSection(repair: repair, isDark: isDark),
      _CostSection(repair: repair, isDark: isDark),
      _TimelineSection(repair: repair, isDark: isDark),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(16.spMin, 12.spMin, 16.spMin, bottomPadding.spMin),
      children: [
        _Header(repair: repair, isDark: isDark),
        SizedBox(height: 16.spMin),
        _QuickActions(repair: repair),
        SizedBox(height: 16.spMin),
        if (wide)
          _twoColumnInfo(infoSections)
        else
          ...infoSections.expand((w) => [w, SizedBox(height: 12.spMin)]),
        // Items section spans the FULL width (wider than the two-column info
        // cards above) so the parts/services table has room to breathe.
        if (repair.items.isNotEmpty) ...[
          SizedBox(height: 12.spMin),
          _ItemsSection(repair: repair, isDark: isDark),
        ],
      ],
    );
  }

  /// Lay the four info cards into two balanced columns for wide panes.
  Widget _twoColumnInfo(List<Widget> sections) {
    final left = <Widget>[];
    final right = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      (i.isEven ? left : right)
        ..add(sections[i])
        ..add(SizedBox(height: 12.spMin));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left)),
        SizedBox(width: 12.spMin),
        Expanded(child: Column(children: right)),
      ],
    );
  }
}

/// Placeholder shown when no repair is selected / available.
class RepairDetailEmpty extends StatelessWidget {
  final String message;
  const RepairDetailEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.click,
            size: 48.spMin,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.spMin),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.spMin, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Opens the repair editor screen.
void openRepairEditor(BuildContext context, Repair repair) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => CreateRepairView(existing: repair)),
  );
}

/// Confirms and deletes a repair. When [popScreenAfter] is true (the standalone
/// detail screen) it also pops back to the list; inline panes pass false.
void confirmDeleteRepair(
  BuildContext context,
  WidgetRef ref,
  Repair repair, {
  bool popScreenAfter = false,
}) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Delete Repair'),
          content: Text(
            'Delete the repair job for ${repair.clientName}? '
            'This cannot be undone.',
            style: TextStyle(fontSize: 13.spMin),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(repairProvider.notifier).deleteRepair(repair.id);
                Navigator.pop(context); // close dialog
                if (popScreenAfter) Navigator.pop(context); // leave detail
                AppFlushbar.success(context, message: 'Repair deleted');
              },
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
  );
}

// ---------------------------------------------------------------------------
// Header: photo, client, status, balance headline
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _Header({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor =
        repair.isCompleted ? AppColors.success : AppColors.warning;

    return Container(
      padding: EdgeInsets.all(20.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg.spMin),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photo(),
              SizedBox(width: 14.spMin),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repair.clientName,
                      style: TextStyle(
                        fontSize: 18.spMin,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (repair.clientPhone.isNotEmpty) ...[
                      SizedBox(height: 2.spMin),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.phone,
                            size: 13.spMin,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4.spMin),
                          Text(
                            repair.clientPhone,
                            style: TextStyle(
                              fontSize: 12.spMin,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 8.spMin),
                    _statusBadge(statusColor),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.spMin),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
          SizedBox(height: 14.spMin),
          // Financial headline — the value is the hero, not the label.
          Row(
            children: [
              Expanded(
                child: _money(
                  label: 'Estimated',
                  value: repair.estimatedCost,
                  color: AppColors.textSecondary,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _money(
                  label: 'Advance Paid',
                  value: repair.advancePaid,
                  color: AppColors.success,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _money(
                  label: 'Balance Due',
                  value: repair.balanceDue,
                  color:
                      repair.balanceDue > 0
                          ? AppColors.error
                          : AppColors.success,
                  emphasize: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 34.spMin,
    color: AppColors.border.withValues(alpha: 0.6),
  );

  Widget _money({
    required String label,
    required double value,
    required Color color,
    bool emphasize = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.spMin, color: Colors.grey[600]),
        ),
        SizedBox(height: 4.spMin),
        Text(
          'Rs ${value.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: emphasize ? 16.spMin : 14.spMin,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _statusBadge(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.spMin, vertical: 4.spMin),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.spMin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            repair.isCompleted
                ? TablerIcons.circle_check
                : TablerIcons.progress,
            size: 13.spMin,
            color: color,
          ),
          SizedBox(width: 5.spMin),
          Text(
            repair.isCompleted ? 'Completed' : 'In Repair',
            style: TextStyle(
              fontSize: 11.spMin,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photo() {
    final path = repair.imageUrl;
    Widget placeholder = Container(
      width: 72.spMin,
      height: 72.spMin,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.spMin),
      ),
      child: Icon(
        TablerIcons.device_laptop,
        color: AppColors.primary,
        size: 30.spMin,
      ),
    );

    if (path == null || path.isEmpty) return placeholder;
    final file = File(path);
    if (!file.existsSync()) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.spMin),
      child: Image.file(
        file,
        width: 72.spMin,
        height: 72.spMin,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions: Call / WhatsApp (exposed, thumb-friendly)
// ---------------------------------------------------------------------------
class _QuickActions extends StatelessWidget {
  final Repair repair;
  const _QuickActions({required this.repair});

  @override
  Widget build(BuildContext context) {
    final hasPhone = repair.clientPhone.trim().isNotEmpty;
    if (!hasPhone) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: TablerIcons.phone,
            label: 'Call',
            color: AppColors.info,
            onTap: () => _launch(context, 'tel:${_digits(repair.clientPhone)}'),
          ),
        ),
        SizedBox(width: 10.spMin),
        Expanded(
          child: _actionButton(
            icon: TablerIcons.brand_whatsapp,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap:
                () => _launch(
                  context,
                  'https://wa.me/${_digits(repair.clientPhone)}',
                ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12.spMin),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.spMin),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.spMin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.spMin, color: color),
              SizedBox(width: 8.spMin),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppFlushbar.error(context, message: 'Could not open $url');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Info section cards
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd.spMin),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.spMin, color: AppColors.primary),
              SizedBox(width: 8.spMin),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.spMin),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.spMin),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.spMin,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.spMin, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 12.spMin,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSection extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _DeviceSection({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Device',
      icon: TablerIcons.device_desktop,
      isDark: isDark,
      children: [
        _InfoRow(label: 'Type', value: repair.deviceType),
        _InfoRow(label: 'Brand', value: repair.brand),
        _InfoRow(label: 'Model', value: repair.model),
        _InfoRow(label: 'Serial No.', value: repair.serialNumber),
      ],
    );
  }
}

class _ProblemSection extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _ProblemSection({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Problem & Accessories',
      icon: TablerIcons.alert_triangle,
      isDark: isDark,
      children: [
        Text(
          'Reported problem',
          style: TextStyle(fontSize: 12.spMin, color: Colors.grey[600]),
        ),
        SizedBox(height: 4.spMin),
        Text(
          repair.problem.trim().isEmpty ? '—' : repair.problem,
          style: TextStyle(fontSize: 13.spMin, height: 1.4),
        ),
        if (repair.accessories.trim().isNotEmpty) ...[
          SizedBox(height: 12.spMin),
          Text(
            'Accessories received',
            style: TextStyle(fontSize: 12.spMin, color: Colors.grey[600]),
          ),
          SizedBox(height: 4.spMin),
          Text(
            repair.accessories,
            style: TextStyle(fontSize: 13.spMin, height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _CostSection extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _CostSection({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Cost Breakdown',
      icon: TablerIcons.cash,
      isDark: isDark,
      children: [
        _costRow('Estimated cost', repair.estimatedCost, null),
        _costRow('Advance paid', repair.advancePaid, AppColors.success),
        Divider(height: 18.spMin, color: AppColors.border.withValues(alpha: 0.6)),
        _costRow(
          'Balance due',
          repair.balanceDue,
          repair.balanceDue > 0 ? AppColors.error : AppColors.success,
          bold: true,
        ),
      ],
    );
  }

  Widget _costRow(String label, double value, Color? color, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.spMin),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.spMin,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? null : Colors.grey[700],
            ),
          ),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: bold ? 14.spMin : 13.spMin,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width list of the parts/services used in the repair.
class _ItemsSection extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _ItemsSection({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items / Parts Used',
      icon: TablerIcons.package,
      isDark: isDark,
      children: [
        // Column headers
        Padding(
          padding: EdgeInsets.only(bottom: 6.spMin),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'Item',
                  style: TextStyle(
                    fontSize: 11.spMin,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.spMin,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.spMin,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.spMin,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
        ...repair.items.map(
          (item) => Padding(
            padding: EdgeInsets.symmetric(vertical: 8.spMin),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    item.name,
                    style: TextStyle(fontSize: 12.spMin),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.spMin),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Rs ${item.price.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.spMin,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Rs ${item.total.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12.spMin,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
        Padding(
          padding: EdgeInsets.only(top: 8.spMin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items Total',
                style: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rs ${repair.itemsTotal.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14.spMin,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final Repair repair;
  final bool isDark;
  const _TimelineSection({required this.repair, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Timeline',
      icon: TablerIcons.calendar,
      isDark: isDark,
      children: [
        _InfoRow(label: 'Received', value: _fmt(repair.receivedDate)),
        _InfoRow(
          label: 'Expected',
          value: repair.expectedDate == null ? '' : _fmt(repair.expectedDate!),
        ),
        _InfoRow(label: 'Last updated', value: _fmt(repair.updatedAt)),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ---------------------------------------------------------------------------
// Bottom status bar — primary CTA in the thumb zone
// ---------------------------------------------------------------------------
class RepairStatusBar extends ConsumerWidget {
  final Repair repair;
  const RepairStatusBar({super.key, required this.repair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = repair.isCompleted;
    final color = completed ? AppColors.warning : AppColors.success;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.spMin, 8.spMin, 16.spMin, 10.spMin),
        child: SizedBox(
          height: 50.spMin,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.spMin),
              ),
            ),
            onPressed: () {
              ref.read(repairProvider.notifier).toggleCompleted(repair.id);
              if (!completed) {
                // Peak moment — celebrate finishing the job.
                AppFlushbar.success(
                  context,
                  message: 'Repair completed 🎉 Ready for pickup',
                );
              }
            },
            icon: Icon(
              completed ? TablerIcons.rotate : TablerIcons.circle_check,
              color: Colors.white,
              size: 20.spMin,
            ),
            label: Text(
              completed ? 'Reopen Repair' : 'Mark as Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.spMin,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
