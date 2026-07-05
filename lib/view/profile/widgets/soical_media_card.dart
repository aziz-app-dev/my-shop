// ignore_for_file: use_build_context_synchronously

import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SoicalMediaCard extends ConsumerWidget {
  const SoicalMediaCard({super.key});

  // Function to launch URL
  Future<void> _launchUrl(String? url, BuildContext context) async {
    if (url == null || url.isEmpty) {
      AppFlushbar.warning(context, message: 'No URL provided');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      // Ensure URL has a scheme (http or https)
      final fixedUrl =
          url.startsWith('http://') || url.startsWith('https://')
              ? url
              : 'https://$url';
      final fixedUri = Uri.parse(fixedUrl);
      if (await canLaunchUrl(fixedUri)) {
        await launchUrl(fixedUri, mode: LaunchMode.externalApplication);
      } else {
        AppFlushbar.error(context, message: 'Cannot open $url');
      }
    } else if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppFlushbar.error(context, message: 'Cannot open $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final instaUrl = profileState.instagram ?? "";
    final facebookUrl = profileState.facebook ?? "";
    final whatsappUrl = profileState.whatsapp ?? "";
    final twitterUrl = profileState.twitter ?? "";

    // List of social media items
    final socialMediaItems = [
      _buildSocialMediaItem(
        context: context,
        // iconPath: 'assets/icons8-facebook-96.png',
        url: facebookUrl,
        label: 'Facebook',
        // scale: 2.2.spMin,
        icon: TablerIcons.brand_facebook,
        win11IconPath: ImageAssets.win11Facebook,
      ),
      _buildSocialMediaItem(
        context: context,
        // iconPath: 'assets/instagram-.png',
        url: instaUrl,
        label: 'Instagram',
        // scale: 2.0.spMin,
        icon: TablerIcons.brand_instagram,
        win11IconPath: ImageAssets.win11Instagram,
      ),
      _buildSocialMediaItem(
        context: context,
        // iconPath: 'assets/whatsapp.png',
        url: whatsappUrl,
        label: 'WhatsApp',
        // scale: 1.8.spMin,
        icon: TablerIcons.brand_whatsapp,
        win11IconPath: ImageAssets.win11Whatsapp,
      ),
      _buildSocialMediaItem(
        context: context,
        // iconPath: 'assets/x.png',
        url: twitterUrl,
        label: 'X',
        icon: TablerIcons.brand_x,
        win11IconPath: ImageAssets.win11X,
        // scale: 2.0.spMin,
      ),
    ];

    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 15.h),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive layout based on screen size
            AppSizes.isDesktop(context)
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: socialMediaItems,
                )
                : AppSizes.isTablet(context)
                ? Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: socialMediaItems[0]),
                        Expanded(child: socialMediaItems[1]),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: socialMediaItems[2]),
                        Expanded(child: socialMediaItems[3]),
                      ],
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      socialMediaItems
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

  Widget _buildSocialMediaItem({
    required BuildContext context,
    required IconData icon,
    required String win11IconPath,
    required String url,
    required String label,
    // required double scale,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _launchUrl(url, context),
          child: AppIcon(
            // color: Colors.grey,
            size: 18.spMin,
            defaultIcon: icon,
            win11IconPath: win11IconPath,
          ),
          // child: Icon(icon, size: 18.spMin),
          // child: Image.asset(iconPath, scale: scale, height: 25.h),
        ),
        SizedBox(width: 2.w),
        smText(
          text: url.isEmpty ? 'N/A' : _truncateUrl(url),
          color: url.isEmpty ? Colors.grey : Colors.blue,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Function to truncate long URLs for display
  String _truncateUrl(String url) {
    if (url.length > 20) {
      return '${url.substring(0, 21)}...';
    }
    return url;
  }
}
