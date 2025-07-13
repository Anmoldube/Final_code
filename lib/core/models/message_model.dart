import 'user_model.dart';
import '../services/timestamp_service.dart';

class MessageModel {
  final String id;
  final String chatId;
  final UserModel sender;
  final String content;
  final MessageType type;
  final List<MessageAttachment> attachments;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final String? replyToId;
  final MessageModel? replyTo;
  final bool isEdited;
  final bool isDeleted;
  final Map<String, dynamic>? metadata;
  final String? senderId; // Add senderId for compatibility

  // Offline sync fields
  final bool isSynced;
  final DateTime? lastSyncedAt;
  final bool isLocalOnly;
  final String?
  localId; // For tracking local messages before they get server IDs
  final List<String>?
  readBy; // List of user IDs who have read the message (backend format)
  final List<String>?
  deliveredTo; // List of user IDs who have received the message
  final DateTime? sentAt; // When message was sent to server
  final DateTime? deliveredAt; // When message was delivered to recipient(s)
  final int? retryCount; // Number of retry attempts
  final String? failureReason; // Reason for failure if status is failed

  /// Returns a list of all participant user IDs for this chat (for tick logic)
  /// This should be set by the provider or injected into the message model for group/1-1 chats.
  List<String>? get chatParticipants =>
      metadata != null && metadata!.containsKey('chatParticipants')
      ? (metadata!['chatParticipants'] as List<dynamic>)
            .map((e) => e.toString())
            .toList()
      : null;

  /// Check if message is read by all participants (for group chats)
  bool get isReadByAll {
    if (chatParticipants == null || readBy == null) return false;
    final otherParticipants = chatParticipants!
        .where((id) => id != senderId)
        .toList();
    return otherParticipants.every((id) => readBy!.contains(id));
  }

  /// Check if message is delivered to all participants
  bool get isDeliveredToAll {
    if (chatParticipants == null || deliveredTo == null) return false;
    final otherParticipants = chatParticipants!
        .where((id) => id != senderId)
        .toList();
    return otherParticipants.every((id) => deliveredTo!.contains(id));
  }

  /// Get the appropriate status for display based on group/individual chat
  MessageStatus get displayStatus {
    if (chatParticipants == null || chatParticipants!.length <= 2) {
      // Individual chat - use the message status directly
      return status;
    } else {
      // Group chat - determine status based on read/delivered arrays
      if (isReadByAll) return MessageStatus.read;
      if (isDeliveredToAll) return MessageStatus.delivered;
      if (status == MessageStatus.sent && (deliveredTo?.isNotEmpty ?? false)) {
        return MessageStatus.delivered;
      }
      return status;
    }
  }

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    this.type = MessageType.text,
    this.attachments = const [],
    this.status = MessageStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
    this.replyToId,
    this.replyTo,
    this.isEdited = false,
    this.isDeleted = false,
    this.metadata,
    this.senderId,
    this.isSynced = true,
    this.lastSyncedAt,
    this.isLocalOnly = false,
    this.localId,
    this.readBy,
    this.deliveredTo,
    this.sentAt,
    this.deliveredAt,
    this.retryCount = 0,
    this.failureReason,
  });

  // Factory constructor for creating from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      chatId: json['chatId'] ?? json['chat'] ?? '',
      sender: json['sender'] is Map<String, dynamic>
          ? UserModel.fromJson(json['sender'])
          : UserModel.empty(),
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      attachments: _parseAttachments(json['attachments']),
      status: _parseMessageStatus(json['status']),
      createdAt:
          TimestampService.parseMessageTimestamp(json['createdAt']) ??
          DateTime.now(),
      updatedAt: TimestampService.parseMessageTimestamp(json['updatedAt']),
      readAt: TimestampService.parseMessageTimestamp(json['readAt']),
      replyToId: json['replyToId'] ?? json['replyTo'],
      replyTo: json['replyToMessage'] != null
          ? MessageModel.fromJson(json['replyToMessage'])
          : null,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      metadata: json['metadata'],
      senderId: json['senderId'] ?? json['sender']?['_id'],
      isSynced: json['isSynced'] ?? true,
      lastSyncedAt: TimestampService.parseMessageTimestamp(
        json['lastSyncedAt'],
      ),
      isLocalOnly: json['isLocalOnly'] ?? false,
      localId: json['localId'],
      readBy: json['readBy'] != null ? List<String>.from(json['readBy']) : null,
      deliveredTo: json['deliveredTo'] != null
          ? List<String>.from(json['deliveredTo'])
          : null,
      sentAt: TimestampService.parseMessageTimestamp(json['sentAt']),
      deliveredAt: TimestampService.parseMessageTimestamp(json['deliveredAt']),
      retryCount: json['retryCount'] ?? 0,
      failureReason: json['failureReason'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'sender': sender.toJson(),
      'content': content,
      'type': type.name,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status.name,
      'createdAt': TimestampService.toIsoString(createdAt),
      'updatedAt': TimestampService.toIsoString(updatedAt),
      'readAt': TimestampService.toIsoString(readAt),
      'replyToId': replyToId,
      'replyToMessage': replyTo?.toJson(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'metadata': metadata,
      'senderId': senderId,
      'isSynced': isSynced,
      'lastSyncedAt': TimestampService.toIsoString(lastSyncedAt),
      'isLocalOnly': isLocalOnly,
      'localId': localId,
      'readBy': readBy,
      'deliveredTo': deliveredTo,
      'sentAt': TimestampService.toIsoString(sentAt),
      'deliveredAt': TimestampService.toIsoString(deliveredAt),
      'retryCount': retryCount,
      'failureReason': failureReason,
    };
  }

  // Copy with method
  MessageModel copyWith({
    String? id,
    String? chatId,
    UserModel? sender,
    String? content,
    MessageType? type,
    List<MessageAttachment>? attachments,
    MessageStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    String? replyToId,
    MessageModel? replyTo,
    bool? isEdited,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
    String? senderId,
    bool? isSynced,
    DateTime? lastSyncedAt,
    bool? isLocalOnly,
    String? localId,
    List<String>? readBy,
    List<String>? deliveredTo,
    DateTime? sentAt,
    DateTime? deliveredAt,
    int? retryCount,
    String? failureReason,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      replyToId: replyToId ?? this.replyToId,
      replyTo: replyTo ?? this.replyTo,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
      senderId: senderId ?? this.senderId,
      isSynced: isSynced ?? this.isSynced,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isLocalOnly: isLocalOnly ?? this.isLocalOnly,
      localId: localId ?? this.localId,
      readBy: readBy ?? this.readBy,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      retryCount: retryCount ?? this.retryCount,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  // Helper methods for parsing
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;
    if (type is MessageType) return type;

    switch (type.toString().toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  static List<MessageAttachment> _parseAttachments(dynamic attachments) {
    if (attachments == null) return [];
    if (attachments is! List) return [];

    return attachments.map((a) => MessageAttachment.fromJson(a)).toList();
  }

  static MessageStatus _parseMessageStatus(dynamic status) {
    if (status == null) return MessageStatus.pending;
    if (status is MessageStatus) return status;

    switch (status.toString().toLowerCase()) {
      case 'pending':
        return MessageStatus.pending;
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.pending;
    }
  }

  /// Check if this message is from the current user
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null) return false;
    return senderId == currentUserId || sender.id == currentUserId;
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, chatId: $chatId, content: $content, type: $type, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MessageAttachment {
  final String id;
  final String url;
  final String? localPath;
  final String? originalName;
  final String? type;
  final int? size;
  final String? thumbnailUrl;
  final int? duration;
  final String? fileMetadataId; // Reference to backend file metadata
  final String? mimeType;
  final String? fileExtension;
  final Map<String, dynamic>? dimensions; // For images/videos
  final Map<String, dynamic>? metadata; // Additional metadata

  const MessageAttachment({
    required this.id,
    required this.url,
    this.localPath,
    this.originalName,
    this.type,
    this.size,
    this.thumbnailUrl,
    this.duration,
    this.fileMetadataId,
    this.mimeType,
    this.fileExtension,
    this.dimensions,
    this.metadata,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] ?? json['_id'] ?? '',
      url: json['url'] ?? '',
      localPath: json['localPath'],
      originalName: json['originalName'],
      type: json['type'],
      size: json['size'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      fileMetadataId: json['fileMetadataId'],
      mimeType: json['mimeType'],
      fileExtension: json['fileExtension'],
      dimensions: json['dimensions'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'localPath': localPath,
      'originalName': originalName,
      'type': type,
      'size': size,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'fileMetadataId': fileMetadataId,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'dimensions': dimensions,
      'metadata': metadata,
    };
  }

  // Getters for UI compatibility
  String get displayName => originalName ?? 'Unknown File';
  String get fileName => originalName ?? 'unknown';
  String get fileType => type ?? mimeType ?? 'unknown';

  // Enhanced getters
  String get fileCategory {
    final mime = mimeType ?? type ?? '';
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    if (mime.contains('pdf')) return 'pdf';
    if (mime.contains('word') || mime.contains('document')) return 'document';
    if (mime.contains('text/')) return 'text';
    return 'other';
  }

  String get extension =>
      fileExtension ?? fileName.split('.').last.toLowerCase();

  String get formattedFileSize {
    if (size == null) return 'Unknown size';

    const int kb = 1024; // 1 KB = 1024 bytes
    const int mb = 1024 * 1024; // 1 MB = 1024 * 1024 bytes
    const int gb = 1024 * 1024 * 1024; // 1 GB = 1024 * 1024 * 1024 bytes

    if (size! >= gb) {
      return '${(size! / gb).toStringAsFixed(1)} GB';
    } else if (size! >= mb) {
      return '${(size! / mb).toStringAsFixed(1)} MB';
    } else if (size! >= kb) {
      return '${(size! / kb).toStringAsFixed(1)} KB';
    } else {
      return '$size B';
    }
  }

  MessageAttachment copyWith({
    String? id,
    String? url,
    String? localPath,
    String? originalName,
    String? type,
    int? size,
    String? thumbnailUrl,
    int? duration,
    String? fileMetadataId,
    String? mimeType,
    String? fileExtension,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? metadata,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      originalName: originalName ?? this.originalName,
      type: type ?? this.type,
      size: size ?? this.size,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      fileMetadataId: fileMetadataId ?? this.fileMetadataId,
      mimeType: mimeType ?? this.mimeType,
      fileExtension: fileExtension ?? this.fileExtension,
      dimensions: dimensions ?? this.dimensions,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'MessageAttachment(id: $id, url: $url, originalName: $originalName, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageAttachment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum MessageType { text, image, file, audio, video }

enum MessageStatus {
  pending, // Clock icon - message not sent yet
  sending, // Clock icon - message being sent
  sent, // One grey tick - sent to server
  delivered, // Two grey ticks - delivered to recipient
  read, // Two blue ticks - read by recipient
  failed, // Red exclamation - failed to send
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.pending:
        return 'Pending';
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  bool get canRetry {
    return this == MessageStatus.failed || this == MessageStatus.pending;
  }

  bool get isSuccessful {
    return this == MessageStatus.sent ||
        this == MessageStatus.delivered ||
        this == MessageStatus.read;
  }

  bool get showSingleTick {
    return this == MessageStatus.sent;
  }

  bool get showDoubleTick {
    return this == MessageStatus.delivered || this == MessageStatus.read;
  }

  bool get showBlueTicks {
    return this == MessageStatus.read;
  }

  bool get showClock {
    return this == MessageStatus.pending || this == MessageStatus.sending;
  }

  bool get showError {
    return this == MessageStatus.failed;
  }
}
