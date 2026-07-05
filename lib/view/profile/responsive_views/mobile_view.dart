import 'package:desktopapp/view/profile/widgets/shop_card.dart';
import 'package:desktopapp/view/profile/widgets/soical_media_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/bank_card.dart';
import '../widgets/owner_card.dart';
import '../widgets/pro_app_bar.dart';

class ProfileMobileView extends ConsumerWidget {
  final VoidCallback openDrawer;

  const ProfileMobileView({super.key, required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      appBar: ProfileAppBar(openDrawer: openDrawer, scaffoldKey: scaffoldKey),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Column(
            spacing: 5.h,
            children: [
              ShopOwnerCard(),
              ShopCard(),
              SoicalMediaCard(),
              BankDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
