import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/message_model.dart';
import '../../data/repositories/message_repository.dart';
import '../states/message_state.dart';
import '../utils/system_message_helper.dart';
import 'message_status_provider.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

final messageProvider = StateNotifierProvider<MessageNotifier, MessageState>((
  ref,
) {
  return MessageNotifier(ref.read(messageRepositoryProvider), ref);
});

class MessageNotifier extends StateNotifier<MessageState> {
  final MessageRepository _messageRepository;
  final Ref _ref;

  MessageNotifier(this._messageRepository, this._ref)
    : super(const MessageState());

  // Check if cached messages are fresh (within 5 minutes)
  bool _areCachedMessagesFresh(String chatId) {
    final lastFetch = state.lastFetchTime[chatId];
    if (lastFetch == null) return false;

    final now = DateTime.now();
    final cacheAge = now.difference(lastFetch);
    const cacheExpiry = Duration(minutes: 5);

    final hasMessages =
        state.messagesByChat.containsKey(chatId) &&
        state.messagesByChat[chatId]!.isNotEmpty;

    return hasMessages && cacheAge < cacheExpiry;
  }

  // Check if chat is fully loaded (has all messages)
  bool _isChatFullyLoaded(String chatId) {
    final boundary = state.chatBoundaries[chatId];
    return boundary?.isFullyLoaded == true;
  }

  // Check if we have cached messages for this chat
  bool _hasCachedMessages(String chatId) {
    return state.messagesByChat.containsKey(chatId) &&
        state.messagesByChat[chatId]!.isNotEmpty;
  }

  // Create or update chat boundary
  void _updateChatBoundary(String chatId, List<MessageModel> messages) {
    if (messages.isEmpty) return;

    // Filter out system messages for boundary calculation
    final realMessages = messages
        .where((msg) => !SystemMessageHelper.isSystemMessage(msg))
        .toList();
    if (realMessages.isEmpty) return;

    final oldestMessage = realMessages.first;
    final newestMessage = realMessages.last;

    final currentBoundary =
        state.chatBoundaries[chatId] ?? ChatBoundary(chatId: chatId);
    final updatedBoundary = currentBoundary.copyWith(
      oldestMessageTime: oldestMessage.createdAt,
      newestMessageTime: newestMessage.createdAt,
      messageCount: realMessages.length,
      isFullyLoaded: true, // Mark as fully loaded after initial fetch
      hasReachedBottom: true,
    );

    final updatedBoundaries = Map<String, ChatBoundary>.from(
      state.chatBoundaries,
    );
    updatedBoundaries[chatId] = updatedBoundary;

    state = state.copyWith(chatBoundaries: updatedBoundaries);
  }

  // Load messages for a specific chat with smart caching
  Future<void> loadMessages(String chatId, {bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // Smart caching: Check if chat is fully loaded and fresh
    if (!forceRefresh) {
      if (_isChatFullyLoaded(chatId) && _areCachedMessagesFresh(chatId)) {
        debugPrint('🔍 Chat $chatId is fully loaded and fresh, skipping fetch');
        return;
      }

      if (_hasCachedMessages(chatId) && _areCachedMessagesFresh(chatId)) {
        debugPrint(
          '🔍 Messages already loaded and fresh for chat $chatId, skipping fetch',
        );
        return;
      }
    }

    debugPrint(
      '🔍 MessageProvider: Loading messages for chat $chatId (force: $forceRefresh, cached: ${_hasCachedMessages(chatId)})',
    );
    state = state.copyWith(isLoading: true, error: null);

    try {
      final messages = await _messageRepository.getMessages(chatId);
      debugPrint(
        '🔍 MessageProvider: Loaded ${messages.length} messages from backend',
      );

      // Sort messages chronologically (oldest first, newest last)
      // This ensures proper chat order with newest messages at the bottom
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
        state.messagesByChat,
      );
      updatedMessagesByChat[chatId] = messages;

      // Add all loaded messages to the message status provider
      final messageStatusNotifier = _ref.read(messageStatusProvider.notifier);
      for (final message in messages) {
        messageStatusNotifier.updateMessage(message);
      }

      // Update last fetch time for this chat
      final updatedLastFetchTime = Map<String, DateTime>.from(
        state.lastFetchTime,
      );
      updatedLastFetchTime[chatId] = DateTime.now();

      // Update chat boundary information
      _updateChatBoundary(chatId, messages);

      state = state.copyWith(
        messagesByChat: updatedMessagesByChat,
        lastFetchTime: updatedLastFetchTime,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Load messages error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load more messages (disabled - using full chat loading instead)
  Future<void> loadMoreMessages(String chatId) async {
    debugPrint(
      '🔍 MessageProvider: Load more messages disabled for chat $chatId - using full chat loading',
    );

    // Check if chat is fully loaded
    if (_isChatFullyLoaded(chatId)) {
      debugPrint('🔍 Chat $chatId is fully loaded, no more messages to fetch');
      return;
    }

    // If not fully loaded, do a full refresh instead
    debugPrint('🔍 Chat $chatId not fully loaded, performing full refresh');
    await loadMessages(chatId, forceRefresh: true);
  }

  // Send a new message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    List<String>? attachments,
    String? replyToId,
  }) async {
    try {
      final message = await _messageRepository.sendMessage(
        chatId: chatId,
        content: content,
        attachments: attachments,
        replyToId: replyToId,
      );

      // Add message to local state immediately for optimistic UI
      _addMessageToChat(chatId, message);

      // Add to message status provider
      final messageStatusNotifier = _ref.read(messageStatusProvider.notifier);
      messageStatusNotifier.updateMessage(message);
    } catch (e) {
      debugPrint('Send message error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Add message to chat (for real-time updates)
  void addMessage(String chatId, MessageModel message) {
    _addMessageToChat(chatId, message);

    // Add to message status provider
    final messageStatusNotifier = _ref.read(messageStatusProvider.notifier);
    messageStatusNotifier.updateMessage(message);
  }

  void _addMessageToChat(String chatId, MessageModel message) {
    final existingMessages = state.messagesByChat[chatId] ?? [];

    // Check if message already exists by ID
    final messageExists = existingMessages.any((msg) => msg.id == message.id);
    if (messageExists) {
      debugPrint(
        '🔍 MessageProvider: Message ${message.id} already exists, skipping duplicate',
      );
      return;
    }

    // Additional check for potential duplicates based on content and timestamp
    // This helps catch messages that might have different IDs but are actually duplicates
    final potentialDuplicate = existingMessages.any(
      (msg) =>
          msg.content == message.content &&
          msg.sender.id == message.sender.id &&
          msg.createdAt.difference(message.createdAt).abs().inSeconds < 2,
    );

    if (potentialDuplicate) {
      debugPrint(
        '🔍 MessageProvider: Potential duplicate message detected, skipping',
      );
      return;
    }

    // Add new message and sort to maintain chronological order
    // This ensures that timestamps are always in proper order
    final updatedMessages = [...existingMessages, message];

    // Sort to maintain chronological order (oldest first, newest last)
    updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
      state.messagesByChat,
    );
    updatedMessagesByChat[chatId] = updatedMessages;

    state = state.copyWith(messagesByChat: updatedMessagesByChat);
    debugPrint(
      '✅ MessageProvider: Added message ${message.id} to chat $chatId (sorted ${updatedMessages.length} messages)',
    );
  }

  // Update a message (for edit, delivery status, etc.)
  void updateMessage(String chatId, MessageModel updatedMessage) {
    final existingMessages = state.messagesByChat[chatId] ?? [];
    final updatedMessages = existingMessages.map((msg) {
      return msg.id == updatedMessage.id ? updatedMessage : msg;
    }).toList();

    final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
      state.messagesByChat,
    );
    updatedMessagesByChat[chatId] = updatedMessages;

    state = state.copyWith(messagesByChat: updatedMessagesByChat);
  }

  // Delete a message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await _messageRepository.deleteMessage(messageId);

      // Remove from local state
      final existingMessages = state.messagesByChat[chatId] ?? [];
      final updatedMessages = existingMessages
          .where((msg) => msg.id != messageId)
          .toList();

      final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
        state.messagesByChat,
      );
      updatedMessagesByChat[chatId] = updatedMessages;

      state = state.copyWith(messagesByChat: updatedMessagesByChat);
    } catch (e) {
      debugPrint('Delete message error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Edit a message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final updatedMessage = await _messageRepository.editMessage(
        messageId,
        newContent,
      );
      updateMessage(chatId, updatedMessage);
    } catch (e) {
      debugPrint('Edit message error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageRepository.markMessageAsRead(messageId);
    } catch (e) {
      debugPrint('Mark message as read error: $e');
    }
  }

  // Mark all messages in chat as read
  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      await _messageRepository.markAllMessagesAsRead(chatId);

      // Update local state
      final existingMessages = state.messagesByChat[chatId] ?? [];
      final updatedMessages = existingMessages.map((msg) {
        return msg.copyWith(readAt: DateTime.now());
      }).toList();

      final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
        state.messagesByChat,
      );
      updatedMessagesByChat[chatId] = updatedMessages;

      state = state.copyWith(messagesByChat: updatedMessagesByChat);
    } catch (e) {
      debugPrint('Mark all messages as read error: $e');
    }
  }

  // Clear chat messages
  Future<void> clearChat(String chatId) async {
    try {
      await _messageRepository.clearChat(chatId);

      final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
        state.messagesByChat,
      );
      updatedMessagesByChat[chatId] = [];

      state = state.copyWith(messagesByChat: updatedMessagesByChat);
    } catch (e) {
      debugPrint('Clear chat error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Send file message
  Future<void> sendFileMessage({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    try {
      final message = await _messageRepository.sendFileMessage(
        chatId: chatId,
        filePath: filePath,
        caption: caption,
      );

      _addMessageToChat(chatId, message);
    } catch (e) {
      debugPrint('Send file message error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Get unread messages count
  Future<int> getUnreadMessagesCount(String chatId) async {
    try {
      return await _messageRepository.getUnreadMessagesCount(chatId);
    } catch (e) {
      debugPrint('Get unread messages count error: $e');
      return 0;
    }
  }

  // Search messages in chat
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      return await _messageRepository.searchMessages(chatId, query);
    } catch (e) {
      debugPrint('Search messages error: $e');
      return [];
    }
  }

  // Get messages for chat (from state)
  List<MessageModel> getMessagesForChat(String chatId) {
    return state.messagesByChat[chatId] ?? [];
  }

  // Clear messages from state when leaving chat (use sparingly)
  void clearChatFromState(String chatId) {
    final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
      state.messagesByChat,
    );
    final updatedLastFetchTime = Map<String, DateTime>.from(
      state.lastFetchTime,
    );
    final updatedBoundaries = Map<String, ChatBoundary>.from(
      state.chatBoundaries,
    );

    updatedMessagesByChat.remove(chatId);
    updatedLastFetchTime.remove(chatId);
    updatedBoundaries.remove(chatId);

    state = state.copyWith(
      messagesByChat: updatedMessagesByChat,
      lastFetchTime: updatedLastFetchTime,
      chatBoundaries: updatedBoundaries,
    );
    debugPrint(
      '🔍 MessageProvider: Cleared messages and boundaries for chat $chatId',
    );
  }

  // Force refresh messages for a chat (clear + reload)
  Future<void> forceRefreshMessages(String chatId) async {
    clearChatFromState(chatId);
    await loadMessages(chatId, forceRefresh: true);
  }

  // Handle typing status
  void setTypingStatus(String chatId, bool isTyping) {
    final updatedTypingStatus = Map<String, bool>.from(state.typingStatus);
    updatedTypingStatus[chatId] = isTyping;
    state = state.copyWith(typingStatus: updatedTypingStatus);
  }

  // Get typing status
  bool isTyping(String chatId) {
    return state.typingStatus[chatId] ?? false;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Add received message from socket
  void addReceivedMessage(MessageModel message) {
    _addMessageToChat(message.chatId, message);

    // Add to message status provider
    final messageStatusNotifier = _ref.read(messageStatusProvider.notifier);
    messageStatusNotifier.updateMessage(message);

    debugPrint(
      '✅ MessageProvider: Added received message to chat ${message.chatId}',
    );
  }

  // Handle typing users for group chats
  void addTypingUser(String chatId, String userId, String userName) {
    final updatedTypingUsers = Map<String, Map<String, String>>.from(
      state.typingUsers,
    );

    if (updatedTypingUsers[chatId] == null) {
      updatedTypingUsers[chatId] = {};
    }

    updatedTypingUsers[chatId]![userId] = userName;
    state = state.copyWith(typingUsers: updatedTypingUsers);
    debugPrint('✅ MessageProvider: User $userName is typing in chat $chatId');
  }

  void removeTypingUser(String chatId, String userId) {
    final updatedTypingUsers = Map<String, Map<String, String>>.from(
      state.typingUsers,
    );

    if (updatedTypingUsers[chatId] != null) {
      updatedTypingUsers[chatId]!.remove(userId);

      if (updatedTypingUsers[chatId]!.isEmpty) {
        updatedTypingUsers.remove(chatId);
      }
    }

    state = state.copyWith(typingUsers: updatedTypingUsers);
    debugPrint(
      '✅ MessageProvider: User $userId stopped typing in chat $chatId',
    );
  }

  // Get typing users for a chat
  List<String> getTypingUsers(String chatId) {
    return state.typingUsers[chatId]?.values.toList() ?? [];
  }

  // Refresh messages for a chat
  Future<void> refreshMessages(String chatId) async {
    final updatedMessagesByChat = Map<String, List<MessageModel>>.from(
      state.messagesByChat,
    );
    updatedMessagesByChat.remove(chatId);
    state = state.copyWith(messagesByChat: updatedMessagesByChat);

    await loadMessages(chatId);
  }
}

// Provider for getting messages for a specific chat
final messagesForChatProvider = Provider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  final messageState = ref.watch(messageProvider);
  return messageState.messagesByChat[chatId] ?? [];
});

// Provider for checking if user is typing in a chat
final typingStatusProvider = Provider.family<bool, String>((ref, chatId) {
  final messageState = ref.watch(messageProvider);
  return messageState.typingStatus[chatId] ?? false;
});
