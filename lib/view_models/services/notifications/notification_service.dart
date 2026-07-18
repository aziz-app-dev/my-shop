import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around [flutter_local_notifications] used by the payment
/// reminder system.
///
/// The app schedules reminders in-process (see `ReminderScheduler`) and calls
/// [showReminder] the moment a payment becomes due while the app is running,
/// so we only rely on the plugin's immediate `show()` — no OS-level scheduling
/// or timezone database is required. Every call is wrapped so a platform that
/// lacks notification support (or a failed init) can never crash the app; the
/// in-app reminders center keeps working regardless.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _available = false;

  /// Whether the OS notification channel initialized successfully. When false
  /// the app silently falls back to in-app reminders only.
  bool get isAvailable => _available;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const macSettings = DarwinInitializationSettings();
      // Stable app identity for Windows toast notifications. The GUID is a
      // fixed random value for this app; it must stay constant across builds.
      const windowsSettings = WindowsInitializationSettings(
        appName: 'My Shop',
        appUserModelId: 'com.myshop.desktopapp',
        guid: 'c8d0f4a2-3b7e-4d6a-9f1c-2e5b7a9d4c31',
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macSettings,
        windows: windowsSettings,
      );

      final ok = await _plugin.initialize(settings);
      _available = ok ?? true;
    } catch (e) {
      _available = false;
      debugPrint('NotificationService init failed (in-app reminders only): $e');
    }
  }

  /// Shows a payment-due notification. [id] should be stable per bill so the
  /// same reminder replaces (rather than stacks) its previous toast.
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_available) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'payment_reminders',
        'Payment Reminders',
        channelDescription: 'Reminders for customer pending payments',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      );
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('NotificationService.showReminder failed: $e');
    }
  }
}
