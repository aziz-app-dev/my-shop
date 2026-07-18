import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../utils/app_sizes.dart';

/// Shared animated shell for the login and register screens.
///
/// - Brand-orange gradient background with a store badge that scales in.
/// - A white card that fades + slides up, holding the form ([child]).
/// - Responsive: the card is width-capped and centered on tablet/desktop,
///   full-width with padding on mobile. Uses `.spMin` per project convention.
class AuthScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _badgeScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxCardWidth = AppSizes.isMobile(context) ? double.infinity : 440.spMin;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFFc74d00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24.spMin,
                vertical: 32.spMin,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store badge.
                    ScaleTransition(
                      scale: _badgeScale,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Container(
                          height: 84.spMin,
                          width: 84.spMin,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(8.spMin),
                          child: ClipOval(
                            child: Image.asset(
                              ImageAssets.appLogo,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.storefront,
                                size: 44.spMin,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.spMin),

                    // Animated card with the form.
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24.spMin),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 22.spMin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6.spMin),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 13.spMin,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 24.spMin),
                              widget.child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
