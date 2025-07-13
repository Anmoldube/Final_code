import 'package:equatable/equatable.dart';

import '../../../../core/models/message_model.dart';

// Chat boundary information
class ChatBoundary extends Equatable {
  final String chatId;
  final DateTime? oldestMessageTime;
  final DateTime? newestMessageTime;
  final bool hasReachedTop;
  final bool hasReachedBottom;
  final bool isFullyLoaded;
  final int messageCount;

  const ChatBoundary({
    required this.chatId,
    this.oldestMessageTime,
    this.newestMessageTime,
    this.hasReachedTop = false,
    this.hasReachedBottom = false,
    this.isFullyLoaded = false,
    this.messageCount = 0,
  });

  ChatBoundary copyWith({
    String? chatId,
    DateTime? oldestMessageTime,
    DateTime? newestMessageTime,
    bool? hasReachedTop,
    bool? hasReachedBottom,
    bool? isFullyLoaded,
    int? messageCount,
  }) {
    return ChatBoundary(
      chatId: chatId ?? this.chatId,
      oldestMessageTime: oldestMessageTime ?? this.oldestMessageTime,
      newestMessageTime: newestMessageTime ?? this.newestMessageTime,
      hasReachedTop: hasReachedTop ?? this.hasReachedTop,
      hasReachedBottom: hasReachedBottom ?? this.hasReachedBottom,
      isFullyLoaded: isFullyLoaded ?? this.isFullyLoaded,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  @override
  List<Object?> get props => [
    chatId,
    oldestMessageTime,
    newestMessageTime,
    hasReachedTop,
    hasReachedBottom,
    isFullyLoaded,
    messageCount,
  ];
}

class MessageState extends Equatable {
  final Map<String, List<MessageModel>> messagesByChat;
  final Map<String, bool> typingStatus;
  final Map<String, Map<String, String>> typingUsers; // chatId -> userId -> userName
  final Map<String, DateTime> lastFetchTime; // Track when messages were last fetched
  final Map<String, ChatBoundary> chatBoundaries; // Track chat boundaries and loading state
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const MessageState({
    this.messagesByChat = const {},
    this.typingStatus = const {},
    this.typingUsers = const {},
    this.lastFetchTime = const {},
    this.chatBoundaries = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  MessageState copyWith({
    Map<String, List<MessageModel>>? messagesByChat,
    Map<String, bool>? typingStatus,
    Map<String, Map<String, String>>? typingUsers,
    Map<String, DateTime>? lastFetchTime,
    Map<String, ChatBoundary>? chatBoundaries,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return MessageState(
      messagesByChat: messagesByChat ?? this.messagesByChat,
      typingStatus: typingStatus ?? this.typingStatus,
      typingUsers: typingUsers ?? this.typingUsers,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      chatBoundaries: chatBoundaries ?? this.chatBoundaries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    messagesByChat,
    typingStatus,
    typingUsers,
    lastFetchTime,
    chatBoundaries,
    isLoading,
    isLoadingMore,
    error,
  ];

  @override
  String toString() {
    return 'MessageState(messagesByChat: ${messagesByChat.length}, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error)';
  }
}
