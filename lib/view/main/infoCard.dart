// ignore_for_file: file_names

import 'package:desktopapp/utils/app_sizes.dart';
import 'package:desktopapp/view/main/main_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../res/colors/app_color.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../view_models/providers/profile_provider.dart';
import '../../view_models/providers/settings_provider.dart';

Widget infoCard(WidgetRef ref) {
  ref.read(profileProvider.notifier).loadUserData();
  final settingsState = ref.watch(settingsProvider);
  final isShowTagLine = settingsState.isShowTagLine;
  final isShowUserCard = settingsState.isShowUserCard;
  final isTagLineInsteadOfCEOName = settingsState.isTagLineInsteadOfCEOName;
  final profileState = ref.watch(profileProvider);

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.h),
    child: Container(
      padding: EdgeInsets.all(6.h),
      decoration: BoxDecoration(
        color:
            (Theme.of(ref.context).brightness == Brightness.dark
                ? Colors.black
                : AppColors.grey100),
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.sm.r)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isShowUserCard
              ? Row(
                spacing: 2.w,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Delay the state update to avoid focus issues
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(selectedIndexProvider.notifier).state = 3;
                        });
                      },
                      child: Container(
                        height: 50.spMin,
                        width: 50.spMin,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                        child:
                            profileState.userImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                  child: Image.file(
                                    profileState.userImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Icon(
                                  Icons.person,
                                  size: 40.spMin,
                                  color: Colors.grey,
                                ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      // spacing: 2.h,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mdTextBold(text: profileState.ownerName, maxLines: 1),
                        xsTextBold(
                          text: profileState.email,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Row(
                spacing: 2.w,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Delay the state update to avoid focus issues
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(selectedIndexProvider.notifier).state = 3;
                        });
                      },
                      child: Container(
                        height: 45.spMin,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child:
                            profileState.shopLogo != null
                                ? Image.file(
                                  profileState.shopLogo!,
                                  fit: BoxFit.cover,
                                )
                                : Icon(
                                  Icons.person,
                                  size: 40.spMin,
                                  color: Colors.grey,
                                ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Column(
                      // spacing: 2.h,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        lgTextBold(text: profileState.shopName),
                        isTagLineInsteadOfCEOName
                            ? Text(
                              profileState.shopTagline ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.kaushanScript(
                                textStyle: TextStyle(
                                  fontSize: 12.spMin,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            )
                            : Row(
                              children: [
                                smTextBold(
                                  text: "CEO: ",
                                  color: AppColors.textSecondary,
                                ),
                                Flexible(
                                  child: smTextBold(
                                    text: profileState.ownerName,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ],
              ),

          isShowTagLine
              ? Padding(
                padding: EdgeInsets.only(left: 2.w, top: 5.h),
                child: Text(
                  profileState.shopTagline ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kaushanScript(
                    textStyle: TextStyle(
                      fontSize: 14.spMin,
                      fontWeight: FontWeight.bold,
                      // color: Colors.black,
                    ),
                  ),
                ),
              )
              : SizedBox.shrink(),

          // Divider(),
        ],
      ),
    ),
  );
}

Widget tabIcon(WidgetRef ref) {
  ref.read(profileProvider.notifier).loadUserData();
  final settingsState = ref.watch(settingsProvider);
  final isShowUserCard = settingsState.isShowUserCard;
  final profileState = ref.watch(profileProvider);

  return SizedBox(
    height: isShowUserCard ? 50.h : 30.h,
    child: Center(
      child: GestureDetector(
        onTap: () => ref.read(selectedIndexProvider.notifier).state = 3,
        child:
            isShowUserCard
                ? Container(
                  height: 50.spMin,
                  width: 50.spMin,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                  child:
                      profileState.userImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            child: Image.file(
                              profileState.userImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Icon(
                            Icons.person,
                            size: 40.spMin,
                            color: Colors.grey,
                          ),
                )
                : Container(
                  height: 45.spMin,
                  // width: 45.spMin,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child:
                      profileState.shopLogo != null
                          ? Image.file(
                            profileState.shopLogo!,
                            fit: BoxFit.cover,
                          )
                          : Icon(
                            Icons.person,
                            size: 40.spMin,
                            color: Colors.grey,
                          ),
                ),
      ),
    ),
  );
}
