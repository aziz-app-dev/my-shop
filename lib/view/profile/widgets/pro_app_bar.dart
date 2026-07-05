import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_icon.dart';
import '../../../routes/routes_name.dart';
import '../../dashboard/dashborad_view.dart';
import '../../expances/expanses_view.dart';
import '../../settings/settings_view.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback openDrawer;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ProfileAppBar({
    super.key,
    required this.openDrawer,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarWidget.customAppBar(
      title: 'Profile',
      context: context,
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: AppIcon(
            // color: Colors.grey,
            size: 18.spMin,
            imgSize: 24.spMin,
            defaultIcon: Icons.more_vert,
            win11IconPath: ImageAssets.win11MenuVertical,
          ),
          // Icon(Icons.more_vert, size: 20.spMin),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.pushNamed(context, RouteName.profileEdit);
            } else if (value == 'dashborad') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboradView()),
              );
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettingsPage(
                        openDrawer:
                            () => scaffoldKey.currentState?.openDrawer(),
                      ),
                ),
              );
            } else if (value == 'expenses') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExpensesView()),
              );
            }
          },
          itemBuilder:
              (context) => [
                _menuItem(
                  icon: TablerIcons.edit,
                  text: 'Edit Profile',
                  value: 'edit',
                  win11IconPath: ImageAssets.win11EditPencil,
                ),
                _menuItem(
                  icon: Icons.branding_watermark,
                  text: 'Dashborad',
                  value: 'dashborad',
                  win11IconPath: ImageAssets.win11Accounting,
                ),
                _menuItem(
                  icon: Icons.settings,
                  text: 'Settings',
                  value: 'settings',
                  win11IconPath: ImageAssets.win11Service,
                ),
                _menuItem(
                  icon: Icons.settings,
                  text: 'Expenses',
                  value: 'expenses',
                  win11IconPath: ImageAssets.win11Invoice,
                ),
              ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem({
    required IconData icon,
    required String win11IconPath,
    required String text,
    required String value,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          AppIcon(
            // color: Colors.grey,
            size: 18.spMin,
            defaultIcon: icon,
            win11IconPath: win11IconPath,
          ),
          // Icon(icon, size: 18.spMin),
          SizedBox(width: 12.w),
          Text(text, style: TextStyle(fontSize: 14.spMin)),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
