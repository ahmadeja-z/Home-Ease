import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

import 'notification_handler.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';
  static const String channelDescription = 'This channel is used for important notifications.';

  Future<void> initialize() async {
    try {
      const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // We use 'initializationSettings' as the positional parameter or 'settings' depending on plugin version
      // If the lint persists, it's definitively 'initializationSettings' (positional) 
      // but let's try 'initializationSettings' first as standard.
      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 [FCM-DEBUG] Local Notification tapped: ${response.payload}');
          if (response.payload != null) {
            NotificationHandler().handlePayload(response.payload!);
          }
        },
      );

      // Create Android Channel
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      debugPrint('✅ [LocalNotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error initializing: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidNotificationDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: 'ticker',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
      debugPrint('🔔 [FCM-DEBUG] Local notification shown. ID: $id');
    } catch (e) {
      debugPrint('❌ [LocalNotificationService] Error showing notification: $e');
    }
  }
}
