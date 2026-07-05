import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../res/assets/image_assets.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/providers/profile_provider.dart';
import 'dart:io';
import 'owner_card.dart';

class BankDetailsCard extends ConsumerWidget {
  const BankDetailsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final bankDetails = profileState.bankDetails;
    // List of bank detail items
    final bankDetailItems =
        bankDetails.isNotEmpty
            ? bankDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final bank = entry.value;
              return _buildBankDetailItem(
                context: context,
                bankName: bank.bankName ?? "",
                accountNumber: bank.accountNumber ?? "",
                ifscCode: bank.ifscCode ?? "",
                qrCode: bank.qrCode,
                index: index,
              );
            }).toList()
            : [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: smText(
                  text: 'No bank details available',
                  color: Colors.grey,
                  textAlign: TextAlign.center,
                ),
              ),
            ];

    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 15.h),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          spacing: 8.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            xlTextBold(text: 'Bank Information'),
            // Responsive layout based on screen size
            if (AppSizes.isDesktop(context))
              // Desktop: Two banks per row
              Column(
                children:
                    bankDetailItems
                        .asMap()
                        .entries
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          if (index % 2 == 0) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Row(
                                spacing: 6.w,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: bankDetailItems[index]),
                                  if (index + 1 < bankDetailItems.length)
                                    Expanded(child: bankDetailItems[index + 1])
                                  else
                                    const Expanded(child: SizedBox.shrink()),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        })
                        .toList(),
              )
            else
              // Tablet and Mobile: One bank per row in a column
              Column(
                spacing: 10.h,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    bankDetailItems
                        .map(
                          (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: item,
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailItem({
    required BuildContext context,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required File? qrCode,
    required int index,
  }) {
    return Container(
      width: AppSizes.isDesktop(context) ? null : double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 15.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryLight1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        spacing: 5.w,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank Details with more space
          Expanded(
            flex: 3, // Give more space to text
            child: Column(
              spacing: 8.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textRow(
                  'Bank Name',
                  bankName,
                  TablerIcons.building_bank,
                  ImageAssets.win11Bank,
                ),
                textRow(
                  'Account',
                  accountNumber,
                  TablerIcons.credit_card,
                  ImageAssets.win11Card,
                ),
                textRow(
                  'IFSC',
                  ifscCode,
                  TablerIcons.regex_off,
                  ImageAssets.win11Nuw,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1, // Reduce QR code space
            child: Container(
              height: 100.spMin, // Reduced size
              width: 100.spMin,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    qrCode != null
                        ? Image.file(
                          qrCode,
                          fit: BoxFit.fill,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                size: 60.spMin,
                                color: Colors.grey,
                              ),
                        )
                        : Icon(
                          Icons.qr_code,
                          size: 60.spMin,
                          color: Colors.grey,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
