import 'package:desktopapp/view/profile/widgets/bank_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/owner_card.dart';
import '../widgets/pro_app_bar.dart';
import '../widgets/shop_card.dart';
import '../widgets/soical_media_card.dart';

class ProfileDeskTabView extends ConsumerWidget {
  final VoidCallback openDrawer;

  const ProfileDeskTabView({super.key, required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      appBar: ProfileAppBar(openDrawer: openDrawer, scaffoldKey: scaffoldKey),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.spMin),
          child: Column(
            spacing: 10.h,
            children: [
              Row(
                spacing: 8.w,
                children: [
                  Expanded(flex: 5, child: ShopOwnerCard()),
                  Expanded(flex: 4, child: ShopCard()),
                ],
              ),
              SoicalMediaCard(),
              BankDetailsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
