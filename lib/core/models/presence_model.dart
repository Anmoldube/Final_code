import 'package:flutter/material.dart';

// Simple presence states
enum PresenceState {
  online('online', 'Online', '🟢'),
  away('away', 'Away', '🟠'),
  idle('idle', 'Idle', '🌙'),
  offline('offline', 'Offline', '⚫');

  const PresenceState(this.value, this.displayName, this.emoji);

  final String value;
  final String displayName;
  final String emoji;

  Color get color {
    switch (this) {
      case PresenceState.online:
        return const Color(0xFF4CAF50); // Green
      case PresenceState.away:
        return const Color(0xFFFF9800); // Orange
      case PresenceState.idle:
        return const Color(0xFF9C27B0); // Purple
      case PresenceState.offline:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData get icon {
    switch (this) {
      case PresenceState.online:
        return Icons.circle;
      case PresenceState.away:
        return Icons.access_time;
      case PresenceState.idle:
        return Icons.bedtime;
      case PresenceState.offline:
        return Icons.circle_outlined;
    }
  }

  static PresenceState fromString(String value) {
    for (final state in PresenceState.values) {
      if (state.value == value) {
        return state;
      }
    }
    return PresenceState.offline;
  }

  // Convenience getters
  bool get isOnline => this == PresenceState.online;
  bool get isAway => this == PresenceState.away;
  bool get isIdle => this == PresenceState.idle;
  bool get isOffline => this == PresenceState.offline;

  @override
  String toString() => value;
}

// Presence settings
class PresenceSettings {
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool enableIdleDetection;
  final bool alwaysShowOnline;
  final bool appearOffline;
  final int idleTimeoutMinutes;

  const PresenceSettings({
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.enableIdleDetection = true,
    this.alwaysShowOnline = false,
    this.appearOffline = false,
    this.idleTimeoutMinutes = 5,
  });

  PresenceSettings copyWith({
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? enableIdleDetection,
    bool? alwaysShowOnline,
    bool? appearOffline,
    int? idleTimeoutMinutes,
  }) {
    return PresenceSettings(
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      enableIdleDetection: enableIdleDetection ?? this.enableIdleDetection,
      alwaysShowOnline: alwaysShowOnline ?? this.alwaysShowOnline,
      appearOffline: appearOffline ?? this.appearOffline,
      idleTimeoutMinutes: idleTimeoutMinutes ?? this.idleTimeoutMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'enableIdleDetection': enableIdleDetection,
      'alwaysShowOnline': alwaysShowOnline,
      'appearOffline': appearOffline,
      'idleTimeoutMinutes': idleTimeoutMinutes,
    };
  }

  factory PresenceSettings.fromJson(Map<String, dynamic> json) {
    return PresenceSettings(
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      enableIdleDetection: json['enableIdleDetection'] ?? true,
      alwaysShowOnline: json['alwaysShowOnline'] ?? false,
      appearOffline: json['appearOffline'] ?? false,
      idleTimeoutMinutes: json['idleTimeoutMinutes'] ?? 5,
    );
  }
}

// User presence info
class UserPresence {
  final String userId;
  final PresenceState state;
  final DateTime lastSeen;
  final String? customStatus;

  const UserPresence({
    required this.userId,
    required this.state,
    required this.lastSeen,
    this.customStatus,
  });

  UserPresence copyWith({
    String? userId,
    PresenceState? state,
    DateTime? lastSeen,
    String? customStatus,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      state: state ?? this.state,
      lastSeen: lastSeen ?? this.lastSeen,
      customStatus: customStatus ?? this.customStatus,
    );
  }

  bool get isOnline => state == PresenceState.online;
  bool get isAway => state == PresenceState.away;
  bool get isIdle => state == PresenceState.idle;
  bool get isOffline => state == PresenceState.offline;

  String getStatusText() {
    // If there's a custom status, return it
    if (customStatus != null && customStatus!.isNotEmpty) {
      return customStatus!;
    }

    // Otherwise return the default state display name
    return state.displayName;
  }

  String getLastSeenText() {
    if (isOnline) return 'Online now';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'Last seen just now';
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    }
    if (difference.inDays < 7) return 'Last seen ${difference.inDays} days ago';

    return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'state': state.value,
      'lastSeen': lastSeen.toIso8601String(),
      'customStatus': customStatus,
    };
  }

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['userId'],
      state: PresenceState.fromString(json['state'] ?? 'offline'),
      lastSeen: DateTime.parse(json['lastSeen']),
      customStatus: json['customStatus'],
    );
  }
}
