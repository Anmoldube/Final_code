import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static late FlutterLocalNotificationsPlugin _notificationsPlugin;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialize settings for macOS
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Initialize settings for Windows
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await _requestDesktopPermissions();
    }

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
  }

  static Future<void> _requestDesktopPermissions() async {
    if (Platform.isMacOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> _createNotificationChannels() async {
    // Channel for new messages
    const AndroidNotificationChannel messageChannel =
        AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'New message notifications',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    // Channel for group messages
    const AndroidNotificationChannel groupMessageChannel =
        AndroidNotificationChannel(
          'group_messages',
          'Group Messages',
          description: 'New group message notifications',
          importance: Importance.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    // Channel for system notifications
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'system',
      'System',
      description: 'System notifications',
      importance: Importance.defaultImportance,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(messageChannel);
      await androidImplementation.createNotificationChannel(
        groupMessageChannel,
      );
      await androidImplementation.createNotificationChannel(systemChannel);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    // This will be handled by the navigation service
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      // Example: {"type": "message", "chatId": "123", "senderId": "456"}
    }
  }

  // Show new message notification
  static Future<void> showMessageNotification({
    required String title,
    required String body,
    required String chatId,
    required String senderId,
    String? groupName,
    String? avatarUrl,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'messages',
          'Messages',
          channelDescription: 'New message notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigTextStyleInformation(''),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'reply',
              'Reply',
              inputs: <AndroidNotificationActionInput>[
                AndroidNotificationActionInput(label: 'Reply message...'),
              ],
            ),
            AndroidNotificationAction('mark_read', 'Mark as Read'),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'message_category',
    );

    const DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'message_category',
    );

    const LinuxNotificationDetails linuxDetails = LinuxNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macOSDetails,
      linux: linuxDetails,
    );

    final payload =
        '{"type": "message", "chatId": "$chatId", "senderId": "$senderId"}';

    await _notificationsPlugin.show(
      chatId.hashCode, // Use chatId hash as notification ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Show group message notification
  static Future<void> showGroupMessageNotification({
    required String groupName,
    required String senderName,
    required String message,
    required String chatId,
    required String senderId,
  }) async {
    if (!_isInitialized) await initialize();

    await showMessageNotification(
      title: groupName,
      body: '$senderName: $message',
      chatId: chatId,
      senderId: senderId,
      groupName: groupName,
    );
  }

  // Show file sharing notification
  static Future<void> showFileNotification({
    required String title,
    required String fileName,
    required String chatId,
    required String messageId,
    bool isDownload = false,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'system',
          'System',
          channelDescription: 'System notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          ongoing: false,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    final payload =
        '{"type": "file", "chatId": "$chatId", "messageId": "$messageId"}';

    await _notificationsPlugin.show(
      messageId.hashCode,
      title,
      fileName,
      notificationDetails,
      payload: payload,
    );
  }

  // Show file upload/download progress
  static Future<void> showProgressNotification({
    required String title,
    required String fileName,
    required int progress,
    required String id,
    bool isIndeterminate = false,
  }) async {
    if (!_isInitialized) await initialize();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'system',
          'System',
          channelDescription: 'File transfer progress',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
          ongoing: true,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          indeterminate: isIndeterminate,
          autoCancel: false,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id.hashCode,
      title,
      '$fileName - $progress%',
      notificationDetails,
    );
  }

  // Show system notification
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'system',
          'System',
          channelDescription: 'System notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    }
    return true; // Assume enabled for other platforms
  }

  // Request notification permission
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } else if (Platform.isMacOS) {
      final MacOSFlutterLocalNotificationsPlugin? macosImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin
              >();
      return await macosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'system',
          'System',
          channelDescription: 'Scheduled notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
    );

    // Note: Scheduling requires additional setup with timezone package
    // This is a placeholder for future implementation
    debugPrint('Scheduled notification for: $scheduledDate');
  }
}
