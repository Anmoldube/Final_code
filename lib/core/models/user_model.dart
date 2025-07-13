import 'user_status.dart';
import '../services/timestamp_service.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final UserStatus status;
  final String? statusMessage;
  final DateTime? lastSeen;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Offline sync fields
  final bool isSynced;
  final DateTime? lastSyncedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.status = UserStatus.offline,
    this.statusMessage,
    this.lastSeen,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,

    this.isSynced = true,
    this.lastSyncedAt,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return username;
    }
  }

  String get initials {
    final name = displayName;
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }

  // Factory method to create an empty user
  factory UserModel.empty() {
    return UserModel(
      id: '',
      username: '',
      email: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Safe parsing of boolean fields
    bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return defaultValue;
    }

    // Safe parsing of DateTime fields using TimestampService
    DateTime parseDateTimeSafely(dynamic value, {DateTime? defaultValue}) {
      final parsed = TimestampService.parseAndValidateDateTime(
        value,
        allowNull: false,
      );
      return parsed ?? defaultValue ?? TimestampService.getCurrentTimestamp();
    }

    // Safe parsing of int fields
    int? parseIntSafely(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Convert backend boolean status to UserStatus enum
    UserStatus convertStatus(dynamic statusValue) {
      // If it's already a string that matches our enum values, use it
      if (statusValue is String) {
        return UserStatus.fromString(statusValue);
      }

      // If it's a boolean (backend format), convert to appropriate status
      if (statusValue is bool) {
        return statusValue ? UserStatus.available : UserStatus.offline;
      }

      // Default to offline
      return UserStatus.offline;
    }

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      avatar: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
      status: convertStatus(json['status']),
      statusMessage: json['statusMessage']?.toString(),
      lastSeen: TimestampService.parseAndValidateDateTime(json['lastSeen']),
      isOnline: parseBoolSafely(
        json['isOnline'],
        defaultValue: parseBoolSafely(json['status'], defaultValue: false),
      ),
      createdAt: parseDateTimeSafely(json['createdAt']),
      updatedAt: parseDateTimeSafely(json['updatedAt']),

      // Offline sync fields
      isSynced: parseBoolSafely(json['isSynced'], defaultValue: true),
      lastSyncedAt: TimestampService.parseAndValidateDateTime(
        json['lastSyncedAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'avatarUrl': avatar, // Include both for compatibility
      'status': status.value,
      'statusMessage': statusMessage,
      'lastSeen': TimestampService.toIsoString(lastSeen),
      'isOnline': isOnline,
      'createdAt': TimestampService.toIsoString(createdAt),
      'updatedAt': TimestampService.toIsoString(updatedAt),

      // Offline sync fields
      'isSynced': isSynced,
      'lastSyncedAt': TimestampService.toIsoString(lastSyncedAt),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    UserStatus? status,
    String? statusMessage,
    DateTime? lastSeen,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,

    bool? isSynced,
    DateTime? lastSyncedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,

      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, displayName: $displayName)';
  }
}

// UserStatus is now imported from user_status.dart
// This provides comprehensive status options for professional use
