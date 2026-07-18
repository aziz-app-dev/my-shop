// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/routes.dart';
import 'view/splash_screen.dart';
import 'view_models/providers/settings_provider.dart';
import 'view_models/providers/sync_provider.dart';
import 'view_models/services/database/database_services.dart';
import 'view_models/services/image_cache/image_cache_service.dart';
import 'view_models/services/notifications/notification_service.dart';
import 'view_models/services/theme/theme_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase. Wrapped so a config hiccup can't white-screen the
  // whole (offline-first) app — local Hive still works without the cloud.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (continuing offline): $e');
  }

  // Initialize Hive with directory management
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize Image Cache Service
  await ImageCacheService.instance.init();

  // Initialize local notifications for the payment reminder system. Wrapped
  // internally so an unsupported platform can't block startup.
  await NotificationService.instance.init();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start background online/offline sync.
    ref.watch(syncControllerProvider);

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final settingsState = ref.watch(settingsProvider);
        final appBarElevation = settingsState.appBarElevation;
        final cardElevation = settingsState.cardElevation;
        final themeMode = settingsState.themeMode;
        final primaryColor = settingsState.primaryColor;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My Shop',
          theme: AppTheme.lightTheme(
            appBarElevation,
            cardElevation,
            primaryColor: primaryColor,
          ),
          darkTheme: AppTheme.darkTheme(
            appBarElevation,
            cardElevation,
            primaryColor: primaryColor,
          ),
          themeMode: themeMode,
          home: SplashScreen(),
          // home: ParallaxOnboarding(),
          // home: AdvancedSplashScreen(
          //   nextScreen: MainScrenn(),
          //   duration: Duration(seconds: 14),
          // ),
          // initialRoute: RouteName.splashScreen,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
