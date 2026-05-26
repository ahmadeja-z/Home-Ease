import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../repositories/user_repository.dart';
import 'local_notification_service.dart';
import 'notification_handler.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Unified Navigator Key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Deduplicate messages (set to store processed message IDs)
  final Set<String> _processedMessageIds = {};
  
  // Track if initial message has been handled
  bool _initialMessageHandled = false;

  /// Centralized initialization for notifications
  Future<void> init() async {
    _log('Initializing notification system...');

    // 1. Initialize local notifications service
    await LocalNotificationService().initialize();

    // 2. Setup FCM listeners
    _setupFcmListeners();

    // 3. Handle initial message (Terminated state)
    await handleInitialMessage();

    // 4. Setup token refresh listener
    setupTokenRefreshListener();

    // 5. Request permissions and sync token
    await requestNotificationPermission();
    await syncToken();

    _log('Initialization complete');
  }

  /// Handle background message (called from main.dart)
  @pragma('vm:entry-point')
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    _log('Background message received: ${message.messageId}');
    // You can add logic here to process data-only messages
  }

  void _setupFcmListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      _log('Foreground message received: ${message.messageId}');
      
      if (message.messageId != null && _processedMessageIds.contains(message.messageId)) {
        _log('Duplicate foreground message detected, skipping: ${message.messageId}');
        return;
      }
      
      if (message.messageId != null) {
        _processedMessageIds.add(message.messageId!);
        // Keep the set size manageable
        if (_processedMessageIds.length > 100) _processedMessageIds.remove(_processedMessageIds.first);
      }

      // Show local notification manually for foreground
      if (message.notification != null) {
        await LocalNotificationService().showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background messages (when user taps on notification tray)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _log('App opened from background notification: ${message.messageId}');
      NotificationHandler().handleRemoteMessage(message);
    });
  }

  /// Handle initial message (Terminated state)
  Future<void> handleInitialMessage() async {
    if (_initialMessageHandled) return;
    
    final RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      _log('Initial message detected: ${message.messageId}');
      _initialMessageHandled = true;
      NotificationHandler().handleRemoteMessage(message);
    }
  }

  // --- Permission & Token Management ---

  Future<void> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }

      await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      _log('Error requesting permission: $e', isError: true);
    }
  }

  Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        final start = DateTime.now();
        while (apnsToken == null && DateTime.now().difference(start).inSeconds < 3) {
          apnsToken = await messaging.getAPNSToken();
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        prefs.setString("fcm", fcmToken);
        _log('FCM Token: $fcmToken');
      }
      return fcmToken ?? '';
    } catch (e) {
      _log('Error getting token: $e', isError: true);
      return '';
    }
  }

  Future<void> syncToken() async {
    try {
      final currentToken = await getDeviceToken();
      if (currentToken.isEmpty) return;

      final userRepo = UserRepository();
      final user = userRepo.currentUser;

      if (user != null && user.id != null) {
        if (user.deviceFcmToken != currentToken) {
          _log('Syncing new FCM token to server...');
          await userRepo.updateFcmToken(currentToken);
        }
      }
    } catch (e) {
      _log('Error syncing token: $e', isError: true);
    }
  }

  void setupTokenRefreshListener() {
    messaging.onTokenRefresh.listen((String newToken) async {
      _log('Token refreshed by FCM');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm", newToken);

      final userRepo = UserRepository();
      if (await userRepo.isUserAuthenticated()) {
        await userRepo.updateFcmToken(newToken);
      }
    });
  }

  Future<void> deleteDeviceToken() async {
    try {
      _log('Invalidating FCM token on logout...');
      await messaging.deleteToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove("fcm");
    } catch (e) {
      _log('Error deleting token: $e', isError: true);
    }
  }

  void _log(String message, {bool isError = false}) {
    final prefix = isError ? '❌ [FCM-DEBUG]' : '🔔 [FCM-DEBUG]';
    debugPrint('$prefix $message');
  }
}

/// Global top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 [FCM-DEBUG] Global background handler received: ${message.messageId}');
  // Process the message here if needed
}
