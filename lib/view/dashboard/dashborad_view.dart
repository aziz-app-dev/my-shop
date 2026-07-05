import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/rapper.dart';
import '../../view_models/providers/dashboard_provider.dart';
import 'responsive_views/dashboard_desktop_view.dart';
import 'responsive_views/dashboard_mobile_view.dart';

class DashboradView extends ConsumerStatefulWidget {
  final VoidCallback? openDrawer;

  const DashboradView({super.key, this.openDrawer});

  @override
  ConsumerState<DashboradView> createState() => _DashboradViewState();
}

class _DashboradViewState extends ConsumerState<DashboradView> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        mobile: DashboardMobileView(openDrawer: widget.openDrawer ?? () {}),
        tablet: DashboardMobileView(openDrawer: widget.openDrawer ?? () {}),
        desktop: DashboardDesktopView(openDrawer: widget.openDrawer),
      ),
    );
  }
}
