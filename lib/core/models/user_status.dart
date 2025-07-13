import 'package:flutter/material.dart';

enum UserStatus {
  available('available', 'Available', 'Ready to chat'),
  away('away', 'Away', 'Temporarily away'),
  busy('busy', 'Busy', 'Do not disturb'),
  inMeeting('in_meeting', 'In a Meeting', 'Currently in a meeting'),
  onCall('on_call', 'On a Call', 'Currently on a phone call'),
  offline('offline', 'Offline', 'Not available'),
  invisible(
    'invisible',
    'Appear Offline',
    'Online but appear offline to others',
  ),
  brb('brb', 'Be Right Back', 'Will be back shortly'),
  lunch('lunch', 'Out to Lunch', 'Taking a lunch break'),
  vacation('vacation', 'On Vacation', 'Currently on vacation');

  const UserStatus(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  // Get status color
  Color get color {
    switch (this) {
      case UserStatus.available:
        return const Color(0xFF4CAF50); // Green
      case UserStatus.away:
        return const Color(0xFFFF9800); // Orange
      case UserStatus.busy:
      case UserStatus.inMeeting:
      case UserStatus.onCall:
        return const Color(0xFFF44336); // Red
      case UserStatus.offline:
      case UserStatus.invisible:
        return const Color(0xFF9E9E9E); // Grey
      case UserStatus.brb:
      case UserStatus.lunch:
        return const Color(0xFFFF9800); // Orange
      case UserStatus.vacation:
        return const Color(0xFF2196F3); // Blue
    }
  }

  // Get status icon
  IconData get icon {
    switch (this) {
      case UserStatus.available:
        return Icons.circle;
      case UserStatus.away:
        return Icons.access_time;
      case UserStatus.busy:
        return Icons.do_not_disturb;
      case UserStatus.inMeeting:
        return Icons.meeting_room;
      case UserStatus.onCall:
        return Icons.phone;
      case UserStatus.offline:
        return Icons.circle_outlined;
      case UserStatus.invisible:
        return Icons.visibility_off;
      case UserStatus.brb:
        return Icons.schedule;
      case UserStatus.lunch:
        return Icons.restaurant;
      case UserStatus.vacation:
        return Icons.beach_access;
    }
  }

  // Get status priority (for sorting)
  int get priority {
    switch (this) {
      case UserStatus.available:
        return 1;
      case UserStatus.away:
      case UserStatus.brb:
        return 2;
      case UserStatus.busy:
      case UserStatus.inMeeting:
      case UserStatus.onCall:
        return 3;
      case UserStatus.lunch:
      case UserStatus.vacation:
        return 4;
      case UserStatus.invisible:
        return 5;
      case UserStatus.offline:
        return 6;
    }
  }

  // Check if user is available for chat
  bool get isAvailable {
    return this == UserStatus.available ||
        this == UserStatus.away ||
        this == UserStatus.brb;
  }

  // Check if user should receive notifications
  bool get shouldReceiveNotifications {
    return this != UserStatus.busy &&
        this != UserStatus.inMeeting &&
        this != UserStatus.onCall &&
        this != UserStatus.offline;
  }

  // Convert from string value
  static UserStatus fromString(String value) {
    for (final status in UserStatus.values) {
      if (status.value == value) {
        return status;
      }
    }
    return UserStatus.offline; // Default fallback
  }

  // Get all available statuses for selection
  static List<UserStatus> get selectableStatuses {
    return [
      UserStatus.available,
      UserStatus.away,
      UserStatus.busy,
      UserStatus.inMeeting,
      UserStatus.onCall,
      UserStatus.brb,
      UserStatus.lunch,
      UserStatus.vacation,
      UserStatus.invisible,
    ];
  }

  // Get quick status options (most commonly used)
  static List<UserStatus> get quickStatuses {
    return [
      UserStatus.available,
      UserStatus.away,
      UserStatus.busy,
      UserStatus.inMeeting,
    ];
  }

  @override
  String toString() => value;
}

// Extension for additional functionality
extension UserStatusExtension on UserStatus {
  // Get status widget
  Widget toWidget({double size = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: this == UserStatus.offline
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: this == UserStatus.offline
          ? null
          : this == UserStatus.busy || this == UserStatus.inMeeting
          ? Icon(Icons.do_not_disturb, size: size * 0.7, color: Colors.white)
          : null,
    );
  }

  // Get formatted time-based status message
  String getTimeBasedMessage() {
    final now = DateTime.now();
    final hour = now.hour;

    switch (this) {
      case UserStatus.away:
        if (hour < 9) return 'Available later this morning';
        if (hour < 12) return 'Back this afternoon';
        if (hour < 17) return 'Back this evening';
        return 'Back tomorrow';

      case UserStatus.lunch:
        return 'Back after lunch';

      case UserStatus.inMeeting:
        return 'In a meeting until ${_getEstimatedEndTime()}';

      case UserStatus.brb:
        return 'Back in a few minutes';

      default:
        return description;
    }
  }

  String _getEstimatedEndTime() {
    final now = DateTime.now();
    final endTime = now.add(const Duration(minutes: 30)); // Estimate 30 min
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }
}

// Status change model for API communication
class StatusChangeRequest {
  final UserStatus status;
  final String? customMessage;
  final DateTime? clearAt;

  StatusChangeRequest({required this.status, this.customMessage, this.clearAt});

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      if (customMessage != null) 'statusMessage': customMessage,
      if (clearAt != null) 'clearAt': clearAt!.toIso8601String(),
    };
  }
}
