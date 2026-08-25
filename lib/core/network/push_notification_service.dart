import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_client.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[PushNotificationService] Background message received: ${message.messageId}');
  }
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'home_business_high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important push notifications from Home Business Marketplace.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    try {
      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request Notification Permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        debugPrint('[PushNotificationService] User granted permission: ${settings.authorizationStatus}');
      }

      // 3. Initialize Local Notifications Plugin for Foreground Heads-Up Banner
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationTapPayload(response.payload!);
          }
        },
      );

      // Create Android Notification Channel
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 4. Listen to Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[PushNotificationService] Foreground Message: ${message.notification?.title}');
        }
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // 5. Handle App Opened from Background / Terminated State
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          debugPrint('[PushNotificationService] Notification Tapped from Background!');
        }
        _handleNotificationMessageTap(message);
      });

      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint('[PushNotificationService] App launched from Terminated Notification!');
        }
        _handleNotificationMessageTap(initialMessage);
      }

      // 6. Token Sync
      await syncFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        syncFCMToken(token: newToken);
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PushNotificationService] Initialization error: $e');
      }
    }
  }

  /// Sync FCM token to backend API if user is authenticated
  static Future<void> syncFCMToken({String? token}) async {
    try {
      final authToken = StorageService.getToken();
      if (authToken == null || authToken.isEmpty) {
        return; // User not logged in yet
      }

      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final platform = Platform.isIOS ? 'IOS' : 'ANDROID';

      await ApiClient.instance.post('/users/device-token', data: {
        'fcmToken': fcmToken,
        'devicePlatform': platform,
      });

      if (kDebugMode) {
        debugPrint('[PushNotificationService] FCM Token synced to backend successfully: $fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PushNotificationService] Failed to sync FCM token: $e');
      }
    }
  }

  static void _handleNotificationMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'PRODUCT_APPROVED' || type == 'PRODUCT_REJECTED') {
      Get.toNamed('/seller-dashboard');
    } else if (type == 'NEW_REVIEW') {
      Get.toNamed('/seller-dashboard');
    } else {
      Get.toNamed('/notifications');
    }
  }

  static void _handleNotificationTapPayload(String payload) {
    Get.toNamed('/notifications');
  }
}
