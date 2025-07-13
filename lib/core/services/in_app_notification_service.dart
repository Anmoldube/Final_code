import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InAppNotificationType {
  success,
  error,
  info,
  warning,
  login,
  logout,
  register,
  profileUpdate,
  fileUpload,
  messageReceived,
}

class InAppNotificationMessage {
  final String id;
  final String title;
  final String message;
  final InAppNotificationType type;
  final DateTime timestamp;
  final Duration? duration;
  final Map<String, dynamic>? data;

  InAppNotificationMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.duration,
    this.data,
  });

  factory InAppNotificationMessage.success({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: InAppNotificationType.success,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 3),
      data: data,
    );
  }

  factory InAppNotificationMessage.error({
    required String title,
    required String message,
    Duration? duration,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: InAppNotificationType.error,
      timestamp: DateTime.now(),
      duration: duration ?? const Duration(seconds: 5),
      data: data,
    );
  }

  factory InAppNotificationMessage.login({
    required String username,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Welcome Back!',
      message: 'Successfully logged in as $username',
      type: InAppNotificationType.login,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 3),
      data: data,
    );
  }

  factory InAppNotificationMessage.register({
    required String username,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Welcome to Chat!',
      message: 'Account created successfully for $username',
      type: InAppNotificationType.register,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 4),
      data: data,
    );
  }

  factory InAppNotificationMessage.logout() {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Goodbye!',
      message: 'You have been logged out successfully',
      type: InAppNotificationType.logout,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 2),
    );
  }

  factory InAppNotificationMessage.profileUpdate({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Profile Updated',
      message: message,
      type: InAppNotificationType.profileUpdate,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 3),
      data: data,
    );
  }

  factory InAppNotificationMessage.fileUpload({
    required String fileName,
    required bool success,
    Map<String, dynamic>? data,
  }) {
    return InAppNotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: success ? 'File Uploaded' : 'Upload Failed',
      message: success 
          ? 'Successfully uploaded $fileName'
          : 'Failed to upload $fileName',
      type: InAppNotificationType.fileUpload,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 3),
      data: data,
    );
  }
}

class InAppNotificationService extends StateNotifier<List<InAppNotificationMessage>> {
  InAppNotificationService() : super([]);

  // Show a notification
  void show(InAppNotificationMessage notification) {
    state = [...state, notification];
    
    // Auto-remove after duration
    if (notification.duration != null) {
      Future.delayed(notification.duration!, () {
        remove(notification.id);
      });
    }
  }

  // Remove a notification
  void remove(String id) {
    state = state.where((notification) => notification.id != id).toList();
  }

  // Clear all notifications
  void clear() {
    state = [];
  }

  // Show success notification
  void showSuccess(String title, String message) {
    show(InAppNotificationMessage.success(
      title: title,
      message: message,
    ));
  }

  // Show error notification
  void showError(String title, String message) {
    show(InAppNotificationMessage.error(
      title: title,
      message: message,
    ));
  }

  // Show login success notification
  void showLoginSuccess(String username) {
    show(InAppNotificationMessage(
      id: DateTime.now().toIso8601String(),
      title: 'Welcome Back!',
      message: 'Successfully logged in as $username',
      type: InAppNotificationType.login,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 3),
      data: {'username': username},
    ));
  }

  // Show registration success notification
  void showRegistrationSuccess(String username) {
    show(InAppNotificationMessage(
      id: DateTime.now().toIso8601String(),
      title: 'Welcome to LAN Messenger!',
      message: 'Account created successfully for $username',
      type: InAppNotificationType.register,
      timestamp: DateTime.now(),
      duration: const Duration(seconds: 4),
      data: {'username': username},
    ));
  }

  // Show logout notification
  void showLogoutSuccess() {
    show(InAppNotificationMessage.logout());
  }

  // Show profile update notification
  void showProfileUpdate(String message) {
    show(InAppNotificationMessage.profileUpdate(message: message));
  }

  // Show file upload notification
  void showFileUpload(String fileName, bool success) {
    show(InAppNotificationMessage.fileUpload(fileName: fileName, success: success));
  }
}

// Provider for notification service
final inAppNotificationServiceProvider = StateNotifierProvider<InAppNotificationService, List<InAppNotificationMessage>>((ref) {
  return InAppNotificationService();
});

// Notification overlay widget
class InAppNotificationOverlay extends ConsumerWidget {
  final Widget child;

  const InAppNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(inAppNotificationServiceProvider);

    return Stack(
      children: [
        child,
        if (notifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              children: notifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InAppNotificationCard(notification: notification),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// Individual notification card
class InAppNotificationCard extends ConsumerWidget {
  final InAppNotificationMessage notification;

  const InAppNotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getBackgroundColor() {
      switch (notification.type) {
        case InAppNotificationType.success:
        case InAppNotificationType.login:
        case InAppNotificationType.register:
        case InAppNotificationType.profileUpdate:
          return Colors.green;
        case InAppNotificationType.error:
          return Colors.red;
        case InAppNotificationType.warning:
          return Colors.orange;
        case InAppNotificationType.logout:
          return Colors.blue;
        case InAppNotificationType.fileUpload:
          return Colors.purple;
        case InAppNotificationType.info:
        default:
          return Colors.blue;
      }
    }

    IconData getIcon() {
      switch (notification.type) {
        case InAppNotificationType.success:
        case InAppNotificationType.profileUpdate:
          return Icons.check_circle;
        case InAppNotificationType.error:
          return Icons.error;
        case InAppNotificationType.warning:
          return Icons.warning;
        case InAppNotificationType.login:
          return Icons.login;
        case InAppNotificationType.register:
          return Icons.person_add;
        case InAppNotificationType.logout:
          return Icons.logout;
        case InAppNotificationType.fileUpload:
          return Icons.upload_file;
        case InAppNotificationType.messageReceived:
          return Icons.message;
        case InAppNotificationType.info:
        default:
          return Icons.info;
      }
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        ref.read(inAppNotificationServiceProvider.notifier).remove(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              getIcon(),
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ref.read(inAppNotificationServiceProvider.notifier).remove(notification.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}