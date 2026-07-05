import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../utils/app_sizes.dart';

/// Auto-scrolling banner carousel for the home page.
///
/// Kept as a [StatefulWidget] so it can drive its own [CarouselSliderController]
/// (reliable auto-play + smooth animation) and track the active page for the
/// dot indicators.
class BannerCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final bool autoScroll;
  final int scrollDuration;

  const BannerCarousel({
    super.key,
    required this.imagePaths,
    required this.autoScroll,
    required this.scrollDuration,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double height =
        AppSizes.isMobile(context)
            ? screenWidth * 0.350
            : screenWidth * 0.150;
    final bool hasMultiple = widget.imagePaths.length > 1;

    return Column(
      children: [
        CarouselSlider(
          carouselController: _controller,
          options: CarouselOptions(
            height: height,
            // Only auto-play when it makes sense: enabled in settings AND there
            // is more than one slide to move between.
            autoPlay: widget.autoScroll && hasMultiple,
            autoPlayInterval: Duration(seconds: widget.scrollDuration),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: false,
            viewportFraction: 1,
            enableInfiniteScroll: hasMultiple,
            onPageChanged: (index, reason) {
              setState(() => _current = index);
            },
          ),
          items:
              widget.imagePaths.map((imagePath) {
                return _BannerSlide(imagePath: imagePath);
              }).toList(),
        ),
        if (hasMultiple) ...[
          SizedBox(height: 10.spMin),
          _buildIndicators(),
        ],
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          widget.imagePaths.asMap().entries.map((entry) {
            final bool isActive = _current == entry.key;
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 20.spMin : 8.spMin,
                height: 8.spMin,
                margin: EdgeInsets.symmetric(horizontal: 3.spMin),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.spMin),
                  color:
                      isActive
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final String imagePath;

  const _BannerSlide({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
        child: Image.file(
          File(imagePath),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    win11IconPath: ImageAssets.win11List,
                    defaultIcon: Icons.broken_image,
                    size: 48.spMin,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8.spMin),
                  Text(
                    'Image not found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.spMin,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
