import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class NotificationService {
  static late FlutterLocalNotificationsPlugin _notificationsPlugin;
  static bool _isInitialized = false;

  static bool get isPlatformSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux;
    } catch (e) {
      return false; // Handle any platform check errors gracefully
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized || !isPlatformSupported) {
      if (kDebugMode) {
        print(
          '⚠ Notification service not initialized: platform not supported or already initialized',
        );
      }
      return;
    }

    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Platform-specific initialization settings
      final initializationSettings = InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: Platform.isIOS ? _darwinSettings : null,
        macOS: Platform.isMacOS ? _darwinSettings : null,
        linux: Platform.isLinux
            ? const LinuxInitializationSettings(
                defaultActionName: 'Open notification',
              )
            : null,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Request permissions for iOS/macOS
      if (Platform.isIOS || Platform.isMacOS) {
        await _requestPermissions();
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('✓ Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('✗ Notification initialization error: $e');
      }
    }
  }

  static const _darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  static Future<void> _requestPermissions() async {
    if (!isPlatformSupported) return;

    try {
      if (Platform.isIOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (Platform.isMacOS) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Permission request error: $e');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }
    // Handle notification tap
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized || !isPlatformSupported) return;

    try {
      final NotificationDetails notificationDetails = NotificationDetails(
        android: Platform.isAndroid
            ? const AndroidNotificationDetails(
                'chat_messages',
                'Chat Messages',
                channelDescription: 'Notifications for chat messages',
                importance: Importance.high,
                priority: Priority.high,
                showWhen: true,
              )
            : null,
        iOS: Platform.isIOS ? const DarwinNotificationDetails() : null,
        macOS: Platform.isMacOS ? const DarwinNotificationDetails() : null,
        linux: Platform.isLinux ? const LinuxNotificationDetails() : null,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Show notification error: $e');
      }
    }
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    if (!isPlatformSupported) return;
    await showNotification(title: senderName, body: message, payload: chatId);
  }

  static Future<void> cancelAll() async {
    if (!_isInitialized || !isPlatformSupported) return;

    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('Cancel all notifications error: $e');
      }
    }
  }

  static Future<void> cancel(int id) async {
    if (!_isInitialized || !isPlatformSupported) return;

    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      if (kDebugMode) {
        print('Cancel notification error: $e');
      }
    }
  }

  static bool get isInitialized => _isInitialized && isPlatformSupported;
}
