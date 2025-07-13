import 'user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final String name;
  final bool isGroupChat;
  final List<UserModel> participants;
  final UserModel? admin;
  final String? lastMessageText;
  final DateTime? lastMessageTimestamp;
  final UserModel? lastMessageSender;
  final MessageType? lastMessageType;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.name,
    required this.isGroupChat,
    required this.participants,
    this.admin,
    this.lastMessageText,
    this.lastMessageTimestamp,
    this.lastMessageSender,
    this.lastMessageType,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isGroup => isGroupChat;
  bool get hasUnreadMessages => unreadCount > 0;

  // Method to get display name with current user context
  String getDisplayName(String? currentUserId) {
    if (isGroupChat) {
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

  // Method to get display avatar with current user context
  String getDisplayAvatar(String? currentUserId) {
    if (isGroupChat) {
      return ''; // For group chats, no specific avatar
    }

    if (participants.isNotEmpty) {
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

  // Method to get other participant with current user context
  UserModel? getOtherParticipant(String? currentUserId) {
    if (!isGroupChat && participants.length >= 2 && currentUserId != null) {
      return participants.firstWhere(
        (user) => user.id != currentUserId,
        orElse: () => participants.first,
      );
    }
    return participants.isNotEmpty ? participants.first : null;
  }

  String get lastMessagePreview {
    if (lastMessageText?.isNotEmpty == true) {
      return lastMessageText!;
    }

    // Generate preview based on message type
    switch (lastMessageType) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📄 Document';
      case MessageType.text:
      default:
        return 'No messages yet';
    }
  }

  String get lastMessageTime {
    if (lastMessageTimestamp != null) {
      final now = DateTime.now();
      final messageTime = lastMessageTimestamp!;
      final difference = now.difference(messageTime);

      if (difference.inDays > 0) {
        if (difference.inDays == 1) {
          return 'Yesterday';
        } else if (difference.inDays < 7) {
          return '${difference.inDays} days ago';
        } else {
          return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
        }
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

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Parse participants first
    final participants =
        (json['participants'] as List<dynamic>?)
            ?.map((p) => UserModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    // Handle admin field
    UserModel? admin;
    if (json['admin'] != null) {
      if (json['admin'] is Map<String, dynamic>) {
        admin = UserModel.fromJson(json['admin']);
      } else if (json['admin'] is String) {
        final adminId = json['admin'] as String;
        try {
          admin = participants.firstWhere((user) => user.id == adminId);
        } catch (e) {
          admin = null;
        }
      }
    }

    // Handle last message sender
    UserModel? lastMessageSender;
    if (json['lastMessageSender'] != null) {
      if (json['lastMessageSender'] is Map<String, dynamic>) {
        lastMessageSender = UserModel.fromJson(json['lastMessageSender']);
      } else if (json['lastMessageSender'] is String) {
        final senderId = json['lastMessageSender'] as String;
        try {
          lastMessageSender = participants.firstWhere(
            (user) => user.id == senderId,
          );
        } catch (e) {
          lastMessageSender = null;
        }
      }
    }

    // Safe parsing helpers
    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

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

    MessageType? parseMessageType(dynamic value) {
      if (value == null) return null;
      final typeString = value.toString().toLowerCase();
      switch (typeString) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'audio':
          return MessageType.audio;
        case 'document':
        case 'file':
          return MessageType.file;
        case 'text':
        default:
          return MessageType.text;
      }
    }

    return ConversationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isGroupChat: json['isGroupChat'] == true,
      participants: participants,
      admin: admin,
      lastMessageText: json['lastMessageText']?.toString(),
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? parseDateTimeSafely(json['lastMessageTimestamp'])
          : null,
      lastMessageSender: lastMessageSender,
      lastMessageType: parseMessageType(json['lastMessageType']),
      unreadCount: parseIntSafely(json['unreadCount']),
      createdAt: parseDateTimeSafely(json['createdAt']),
      updatedAt: parseDateTimeSafely(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'isGroupChat': isGroupChat,
      'participants': participants.map((p) => p.toJson()).toList(),
      'admin': admin?.toJson(),
      'lastMessageText': lastMessageText,
      'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
      'lastMessageSender': lastMessageSender?.toJson(),
      'lastMessageType': lastMessageType?.name,
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    String? name,
    bool? isGroupChat,
    List<UserModel>? participants,
    UserModel? admin,
    String? lastMessageText,
    DateTime? lastMessageTimestamp,
    UserModel? lastMessageSender,
    MessageType? lastMessageType,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      participants: participants ?? this.participants,
      admin: admin ?? this.admin,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ConversationModel(id: $id, name: $name, isGroupChat: $isGroupChat, participants: ${participants.length})';
  }
}
