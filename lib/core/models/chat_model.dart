import 'user_model.dart';
import 'message_model.dart';
import '../services/chat_debug_service.dart';

class ChatModel {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final List<UserModel> participants;
  final UserModel? admin;
  final MessageModel? lastMessage;
  final String? avatar;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isDefault; // New field for default groups
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivity;

  // Offline sync fields
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final bool isLocalOnly;

  const ChatModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.participants,
    this.admin,
    this.lastMessage,
    this.avatar,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivity,
    this.isSynced = true,
    this.lastSyncedAt,
    this.isLocalOnly = false,
  });

  bool get isGroup => type == ChatType.group;
  bool get isOneOnOne => type == ChatType.oneOnOne;

  // Method to get display name with current user context
  String getDisplayName(String? currentUserId) {
    if (isGroup) {
      return name;
    } else {
      // For one-on-one chats, return the other participant's name
      if (currentUserId != null && participants.isNotEmpty) {
        final otherParticipant = participants.firstWhere(
          (user) => user.id != currentUserId,
          orElse: () => participants.first,
        );
        return otherParticipant.displayName;
      }
      // Fallback if no current user ID provided
      return participants.isNotEmpty ? participants.first.displayName : name;
    }
  }

  // Legacy getter for backward compatibility
  String get displayName {
    return getDisplayName(currentUserId.isNotEmpty ? currentUserId : null);
  }

  // Method to get display avatar with current user context
  String getDisplayAvatar(String? currentUserId) {
    if (avatar != null) return avatar!;

    if (isOneOnOne && participants.isNotEmpty) {
      if (currentUserId != null) {
        final otherParticipant = participants.firstWhere(
          (user) => user.id != currentUserId,
          orElse: () => participants.first,
        );
        return otherParticipant.avatar ?? '';
      }
      // Fallback if no current user ID provided
      return participants.first.avatar ?? '';
    }

    return '';
  }

  // Legacy getter for backward compatibility
  String get displayAvatar {
    return getDisplayAvatar(currentUserId.isNotEmpty ? currentUserId : null);
  }

  // Method to get other participant with current user context
  UserModel? getOtherParticipant(String? currentUserId) {
    if (isOneOnOne && participants.length >= 2 && currentUserId != null) {
      return participants.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => participants.first,
      );
    }
    return participants.isNotEmpty ? participants.first : null;
  }

  // Legacy getter for backward compatibility
  UserModel? get otherParticipant {
    return getOtherParticipant(currentUserId.isNotEmpty ? currentUserId : null);
  }

  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';

    final message = lastMessage!;
    if (message.type == MessageType.text) {
      return message.content;
    } else if (message.type == MessageType.image) {
      return '📷 Photo';
    } else if (message.type == MessageType.file) {
      return '📎 File';
    } else if (message.type == MessageType.audio) {
      return '🎵 Audio';
    } else if (message.type == MessageType.video) {
      return '🎥 Video';
    } else {
      return 'Message';
    }
  }

  String get lastMessageTime {
    if (lastMessage?.createdAt != null) {
      final now = DateTime.now();
      final messageTime = lastMessage!.createdAt;
      final difference = now.difference(messageTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    return '';
  }

  bool get hasUnreadMessages => unreadCount > 0;

  // This should be set from the authentication state
  static String currentUserId = '';

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Debug raw data first
    ChatDebugService.debugRawChatData(json);

    // Parse participants first
    final participants =
        (json['participants'] as List<dynamic>?)
            ?.map((p) => UserModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    // Handle admin field - it could be a Map (user object) or String (user ID)
    UserModel? admin;
    if (json['admin'] != null) {
      if (json['admin'] is Map<String, dynamic>) {
        admin = UserModel.fromJson(json['admin']);
      } else if (json['admin'] is String) {
        // Find admin user from participants list using the admin ID
        final adminId = json['admin'] as String;
        try {
          admin = participants.firstWhere((user) => user.id == adminId);
        } catch (e) {
          // If admin not found in participants, set to null
          admin = null;
        }
      }
    }

    // Safe parsing of numeric fields that might come as strings
    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    // Safe parsing of boolean fields
    bool parseBoolSafely(dynamic value, {bool defaultValue = false}) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return defaultValue;
    }

    // Safe parsing of DateTime fields
    DateTime parseDateTimeSafely(dynamic value, {DateTime? defaultValue}) {
      if (value == null) return defaultValue ?? DateTime.now();
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue ?? DateTime.now();
        }
      }
      return defaultValue ?? DateTime.now();
    }

    final chatModel = ChatModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: ChatType.fromString(
        json['isGroupChat'] == true ? 'group' : 'oneOnOne',
      ),
      participants: participants,
      admin: admin,
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      avatar: json['avatar']?.toString(),
      unreadCount: parseIntSafely(json['unreadCount']),
      isMuted: parseBoolSafely(json['isMuted']),
      isPinned: parseBoolSafely(json['isPinned']),
      isDefault: parseBoolSafely(json['isDefault']),
      createdAt: parseDateTimeSafely(json['createdAt']),
      updatedAt: parseDateTimeSafely(json['updatedAt']),
      lastActivity: json['lastActivity'] != null
          ? parseDateTimeSafely(json['lastActivity'])
          : null,
      // Offline sync fields
      isSynced: parseBoolSafely(json['isSynced'], defaultValue: true),
      lastSyncedAt: json['lastSyncedAt'] != null
          ? parseDateTimeSafely(json['lastSyncedAt'])
          : null,
      isLocalOnly: parseBoolSafely(json['isLocalOnly'], defaultValue: false),
    );

    // Debug the final parsed chat
    if (chatModel.isGroup) {
      ChatDebugService.debugChatParticipants(chatModel);
    }

    return chatModel;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'type': type.name,
      // For backend compatibility
      'isGroupChat': type == ChatType.group,
      'participants': participants.map((p) => p.toJson()).toList(),
      'admin': admin?.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'avatar': avatar,
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      // Offline sync fields
      'isSynced': isSynced,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'isLocalOnly': isLocalOnly,
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    List<UserModel>? participants,
    UserModel? admin,
    MessageModel? lastMessage,
    String? avatar,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivity,
    bool? isSynced,
    DateTime? lastSyncedAt,
    bool? isLocalOnly,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      admin: admin ?? this.admin,
      lastMessage: lastMessage ?? this.lastMessage,
      avatar: avatar ?? this.avatar,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivity: lastActivity ?? this.lastActivity,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatModel(id: $id, name: $name, type: $type, participants: ${participants.length})';
  }
}

enum ChatType {
  oneOnOne,
  group;

  static ChatType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'group':
        return ChatType.group;
      case 'oneonone':
      case 'one-on-one':
      case 'direct':
      case 'private':
      default:
        return ChatType.oneOnOne;
    }
  }

  String get displayName {
    switch (this) {
      case ChatType.oneOnOne:
        return 'Direct Message';
      case ChatType.group:
        return 'Group Chat';
    }
  }
}
