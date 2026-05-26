import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../routes/route_names.dart';
import 'notification_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  /// Handle message when app is in foreground, background, or terminated
  Future<void> handleRemoteMessage(RemoteMessage message) async {
    _log('Handling RemoteMessage: ID=${message.messageId}');
    _log('Data Payload: ${message.data}');

    _navigateBasedOnData(message.data);
  }

  /// Handle payload from LocalNotificationService
  Future<void> handlePayload(String payload) async {
    try {
      _log('Handling Raw Payload String: $payload');
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateBasedOnData(data);
    } catch (e) {
      _log('Error parsing payload JSON: $e', isError: true);
    }
  }

  /// Centralized navigation logic
  void _navigateBasedOnData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      _log('Empty data payload, skipping navigation');
      return;
    }

    try {
      final String? type = data['type']?.toString();
      final String? id =
          (data['id'] ?? data['orderId'] ?? data['chatId'] ?? data['jobId'])
              ?.toString();

      _log('Navigation Analysis -> Type: $type, ID: $id');

      _performNavigation((navigator) {
        switch (type) {
          case 'chat':
            _log('Action: Navigating to Chat screen with RoomID: $id');
            // navigator.pushNamed(RouteNames.chatDetail, arguments: id);
            break;

          case 'order':
          case 'job':
          case 'booking':
            _log('Action: Navigating to Order details. ID: $id');
            // navigator.pushNamed(RouteNames.orderDetails, arguments: id);
            break;

          case 'verification_update':
            _log('Action: Navigating to Profile/Home for status update');
            navigator.pushNamed(RouteNames.nav);
            break;

          default:
            _log('Action: Unknown type "$type", defaulting to Home');
            navigator.pushNamedAndRemoveUntil(RouteNames.nav, (route) => false);
            break;
        }
      });
    } catch (e) {
      _log('Navigation Logic Error: $e', isError: true);
    }
  }

  /// Helper to wait for the navigator context
  void _performNavigation(Function(NavigatorState) navAction) {
    int attempts = 0;
    const maxAttempts = 10;

    void attempt() {
      final NavigatorState? state =
          NotificationService.navigatorKey.currentState;

      if (state != null) {
        _log('Navigator is ready, executing action');
        navAction(state);
      } else if (attempts < maxAttempts) {
        attempts++;
        _log(
          'Navigator not ready (attempt $attempts/$maxAttempts), retrying in 500ms...',
        );
        Future.delayed(const Duration(milliseconds: 500), attempt);
      } else {
        _log(
          'Navigator failed to become ready after $maxAttempts attempts',
          isError: true,
        );
      }
    }

    attempt();
  }

  void _log(String message, {bool isError = false}) {
    final prefix = isError ? '❌ [FCM-DEBUG]' : '🚀 [FCM-DEBUG]';
    debugPrint('$prefix $message');
  }
}
