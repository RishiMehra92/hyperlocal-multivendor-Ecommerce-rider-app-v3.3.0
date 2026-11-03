import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../config/global.dart';
import '../screens/feed_page/repo/order_details.dart';
import '../screens/dashboard/bloc/notification/notification_bloc.dart';
import '../screens/feed_page/bloc/available_orders_bloc/available_orders_bloc.dart';
import '../screens/feed_page/bloc/available_orders_bloc/available_orders_event.dart';
import '../screens/feed_page/widgets/order_ready_banner.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Skip if it's a silent notification (no notification object)
  if (message.notification == null) {
    log('Ignoring silent push notification (likely auth related)');
    return;
  }

  log('Handling background notification: ${message.messageId}');
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static OverlayEntry? _currentBannerEntry;
  static final List<int> _pendingOrderQueue = [];
  static bool _isBannerShowing = false;
  static int? _currentShowingOrderId;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      log('⚠️ NotificationManager already initialized');
      return;
    }

    try {
      log('🔔 Initializing NotificationManager...');

      // Request permission
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Handle terminated state (initial message)
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        log(
          '🚀 App launched from notification (terminated): ${initialMessage.messageId}',
        );
        // Small delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentContext != null) {
            BlocProvider.of<NotificationBloc>(
              navigatorKey.currentContext!,
            ).add(FetchNotifications());
          }
          _handleNotificationTap(initialMessage);
        });
      }

      // Get and save FCM token
      await _retrieveAndSaveFCMToken();

      _initialized = true;
      log('✅ NotificationManager initialization complete');
    } catch (e) {
      log('❌ NotificationManager initialization error: $e');
      rethrow;
    }
  }

  Future<void> requestPermission() async {
    try {
      log('📱 Requesting notification permission...');

      // Match working project sequence

      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (Platform.isIOS) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      log('📱 Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting permission: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high importance channel for Android to ensure background popups work
    final androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Important notifications for orders and updates.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          enableLights: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'special_notification_channel',
          'Special Notifications',
          description: 'Custom sound notifications for special events.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
            'new_order_foreground_sound',
          ),
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Main message Heree $message");
      log('📨 Foreground message received : ${message.messageId}');
      log('📨 Foreground message received: ${message.senderId}');
      log('📨 Foreground message received: ${message.threadId}');

      log('Title: ${message.notification?.title}');
      log('Body: ${message.notification?.body}');
      log('Data: ${message.data}');
      log("Image Here: ${message.notification?.android?.imageUrl}");

      final type = message.data['type']?.toString();
      if (type == 'order_ready_for_pickup') {
        _showOrderReadyBanner(message);
      } else {
        _showLocalNotification(message);
      }

      // _showLocalNotification(message);

      if (navigatorKey.currentContext != null) {
        BlocProvider.of<NotificationBloc>(
          navigatorKey.currentContext!,
        ).add(FetchNotifications());

        if (shellNavigatorKey.currentContext != null) {
          _callFunctionsOnNotifications(message);
        }
      }
    });
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📬 Notification tapped (backgrasdound): ${message.messageId}');

      _handleNotificationTap(message);
      if (navigatorKey.currentContext != null) {
        BlocProvider.of<NotificationBloc>(
          navigatorKey.currentContext!,
        ).add(FetchNotifications());
        if (shellNavigatorKey.currentContext != null) {
          _callFunctionsOnNotifications(message);
        }
      }
    });

    // Handle background messages - now called in main.dart
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _retrieveAndSaveFCMToken() async {
    try {
      log('🔑 Retrieving FCM & APNs tokens...');
      String? fcmToken = await _firebaseMessaging.getToken();
      log('🔑 FCM Token retrieved: $fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await Global.setFCMToken(fcmToken); // 2/4/26
        log('✅ FCM Token saved to Hive');
      }
      //   }

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('🔄 FCM Token refreshed: $newToken');

        await Global.setFCMToken(newToken);
      });
    } catch (e) {
      log('❌ Error retrieving tokens: $e');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName';
    await Dio().download(url, filePath);
    return filePath;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    String? imageUrl =
        notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    List<DarwinNotificationAttachment>? attachments;

    String? localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String fileName = 'notification_img_${notification.hashCode}.jpg';
        final String filePath = await _downloadAndSaveFile(imageUrl, fileName);
        log('✅ Notification image downloaded to: $filePath');
        localImagePath = filePath;

        bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(filePath),
          largeIcon: FilePathAndroidBitmap(filePath),
          contentTitle: notification.title,
          summaryText: notification.body,
          hideExpandedLargeIcon: false,
        );

        attachments = [DarwinNotificationAttachment(filePath)];
      } catch (e) {
        log('❌ Error downloading notification image: $e');
      }
    }

    final type = message.data['type']?.toString();
    final bool useSpecialSound =
        type == 'delivery' ||
        type == 'order_ready_for_pickup' ||
        type == 'return_order_available';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          useSpecialSound
              ? 'special_notification_channel'
              : 'high_importance_channel',
          useSpecialSound
              ? 'Special Notifications'
              : 'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon:
              localImagePath != null
                  ? FilePathAndroidBitmap(localImagePath)
                  : null,
          sound: RawResourceAndroidNotificationSound(
            useSpecialSound ? 'new_order_foreground_sound' : 'notification',
          ),
          fullScreenIntent: true,
          enableVibration: true,
          enableLights: true,
          styleInformation: bigPictureStyleInformation,
        );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      subtitle: '',
      threadIdentifier: 'foreground_threat',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound:
          useSpecialSound
              ? 'new_order_foreground_sound.mp3'
              : 'notification.wav',
      attachments: attachments,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);

        // 2. Extract the type
        final type = payloadData['type']?.toString();

        // 3. Send it directly to your redirection logic
        if (type != null) {
          handleTypeRedirection(type, payloadData);
        }
      } catch (e) {}
    }

    // Handle notification tap
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('📬 Handling notification tap: ${message.data}');

    final type = message.data['type']?.toString();
    final metadata = message.data;
    if (type != null) {
      handleTypeRedirection(type, metadata);
    }
  }

  void handleTypeRedirection(
    String type,
    dynamic metadata, {
    bool fromNotificationScreen = false,
  }) {
    log('🧭 Redirecting for type: $type');
    String? notificationId = metadata?['notification_id'];

    if (notificationId != null) {
      BlocProvider.of<NotificationBloc>(
        navigatorKey.currentContext!,
      ).add(MarkAsRead(notificationId));
    }
    try {
      switch (type) {
        case 'wallet_transaction':
          MyAppRoute.pushUnique(AppRoutes.allEarnings);
          break;
        case 'refer_transaction':
          MyAppRoute.pushUnique(AppRoutes.viewTransactions);
          break;
        case 'withdrawal_request':
        case 'withdrawal_process':
          MyAppRoute.pushUnique(AppRoutes.withdrawalHistory);
          break;
        case 'settlement_process':
        case 'settlement_create':
          MyAppRoute.pushUnique(AppRoutes.earnings);
          break;
        case 'order_ready_for_pickup':
        case 'delivery':
          // FeedPage available orders tab
          MyAppRoute.goUnique('${AppRoutes.feed}?tab=0');
          break;
        case 'return_order_available':
        case 'return_order':
          // FeedPage return orders tab
          MyAppRoute.goUnique('${AppRoutes.feed}?tab=1');
          break;
        case 'order_update':
          if (metadata != null && metadata['order_id'] != null) {
            final int orderId = int.parse(metadata['order_id'].toString());
            // Constructing a consistent location string for comparison
            MyAppRoute.pushUnique(
              AppRoutes.orderDetails,
              extra: {'orderId': orderId, 'from': true},
            );
          }
          break;
        default:
          log('⚠️ Unknown notification type: $type');
          // Default to notifications list if type is unknown but tapped
          if (!fromNotificationScreen) {
            MyAppRoute.pushUnique(AppRoutes.notifications);
          }
      }
    } catch (e) {
      log('❌ Redirection error: $e');
    }
  }

  void _callFunctionsOnNotifications(RemoteMessage message) {
    try {
      final type = message.data['type']?.toString();
      if (type == null) return;

      switch (type) {
        case 'order_ready_for_pickup':
        case 'delivery':
          final context = shellNavigatorKey.currentContext;
          if (context != null) {
            BlocProvider.of<AvailableOrdersBloc>(
              context,
            ).add(AllAvailableOrdersList(forceRefresh: true));
          } else {
            log(
              '⚠️ Cannot refresh AvailableOrdersBloc: shellNavigatorKey.currentContext is null',
            );
          }
          break;

        default:
          log('ℹ️ No custom function triggered for notification type: $type');
          break;
      }
    } catch (e, stackTrace) {
      log('❌ Error in _callFunctionsOnNotifications: $e\n$stackTrace');
    }
  }

  Future<bool> _isOrderReadyForPickup(int orderId) async {
    try {
      final repo = OrderDetailsRepo();
      final response = await repo.getOrderDetails(orderId);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final orderData = data['order'] is Map ? data['order'] : null;
        final status =
            (orderData != null ? orderData['status'] : data['status'])
                ?.toString();
        if (status == 'ready_for_pickup') {
          return true;
        }
      }
      return false;
    } catch (e) {
      log('❌ Error checking order status in NotificationManager: $e');
      return false;
    }
  }

  void _showOrderReadyBanner(RemoteMessage message) async {
    try {
      final orderIdStr = message.data['order_id']?.toString();
      if (orderIdStr == null) return;
      final orderId = int.tryParse(orderIdStr);
      if (orderId == null) return;

      // Check order status from API using repo before showing
      final isReady = await _isOrderReadyForPickup(orderId);
      if (!isReady) {
        log('Order $orderId is not ready_for_pickup, skipping banner.');
        return;
      }

      if (_isBannerShowing) {
        if (_currentShowingOrderId != orderId &&
            !_pendingOrderQueue.contains(orderId)) {
          _pendingOrderQueue.add(orderId);
          log(
            'Queueing order $orderId. Current queue size: ${_pendingOrderQueue.length}',
          );
        } else {
          log('Order $orderId is already showing or queued.');
        }
        return;
      }

      _displayBanner(orderId);
    } catch (e, stackTrace) {
      log('❌ Error showing OrderReadyBanner: $e\n$stackTrace');
    }
  }

  void _displayBanner(int orderId) {
    final context = navigatorKey.currentContext;
    final overlayState = navigatorKey.currentState?.overlay;

    if (context == null || overlayState == null) {
      log(
        '⚠️ Cannot show OrderReadyBanner for $orderId: Context or Overlay is null. Will retry in 2 seconds.',
      );
      // Re-queue and try again later so the queue doesn't get permanently stuck
      if (!_pendingOrderQueue.contains(orderId)) {
        _pendingOrderQueue.insert(0, orderId);
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (_pendingOrderQueue.isNotEmpty && !_isBannerShowing) {
          final nextOrderId = _pendingOrderQueue.removeAt(0);
          _displayBanner(nextOrderId);
        }
      });
      return;
    }

    _isBannerShowing = true;
    _currentShowingOrderId = orderId;

    _currentBannerEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black54)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OrderReadyBanner(
                orderId: orderId,
                onDismiss: () {
                  if (_currentBannerEntry != null) {
                    _currentBannerEntry?.remove();
                    _currentBannerEntry = null;
                  }
                  _isBannerShowing = false;
                  _currentShowingOrderId = null;

                  if (_pendingOrderQueue.isNotEmpty) {
                    final nextOrderId = _pendingOrderQueue.removeAt(0);
                    Future.delayed(const Duration(milliseconds: 350), () {
                      _displayBanner(nextOrderId);
                    });
                  }
                },
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_currentBannerEntry!);
  }
}

// Background message handler (must be top-level function)
