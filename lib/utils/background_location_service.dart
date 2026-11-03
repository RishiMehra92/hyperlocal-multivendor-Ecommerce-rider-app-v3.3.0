import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/utils/location_tracker.dart';

/// Handles background location service initialization and lifecycle.
class BackgroundLocationService {
  /// Initialize and configure the background service.
  static Future<void> initializeService() async {
    await _ensureLocationTrackingNotificationChannel();

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracker_channel',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Tracking your location for deliveries',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Ensure the Android notification channel for location tracking exists.
  static Future<void> _ensureLocationTrackingNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'location_tracker_channel',
      'Location Tracker Service',
      description: 'Foreground service for delivery location updates',
      importance: Importance.low,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Restart background services if the delivery boy was previously online.
  static Future<void> restartServicesIfNeeded() async {
    try {
      final wasOnline = await Global.getDeliveryBoyStatus();
      if (wasOnline == true) {
        final service = FlutterBackgroundService();
        if (!await service.isRunning()) {
          await service.startService();
        }
        service.invoke('setUpdateInterval', {'seconds': 5});
        service.invoke('triggerNow');
      }
    } catch (e) {
      log('Error checking delivery status: $e');
    }
  }
}
