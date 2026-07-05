import 'package:desktopapp/view/home/rapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_models/providers/profile_provider.dart';
import 'responsive_views/desktop_tab_view.dart';
import 'responsive_views/mobile_view.dart';

class ProfileView extends ConsumerStatefulWidget {
  final VoidCallback openDrawer;

  const ProfileView({super.key, required this.openDrawer});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        mobile: ProfileMobileView(openDrawer: widget.openDrawer),
        tablet: ProfileDeskTabView(openDrawer: widget.openDrawer),
        desktop: ProfileDeskTabView(openDrawer: widget.openDrawer),
      ),
    );
  }
}
