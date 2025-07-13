import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/repositories/conversation_repository.dart';
import '../states/conversation_state.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepository();
});

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, ConversationState>((ref) {
      return ConversationNotifier(ref.read(conversationRepositoryProvider));
    });

class ConversationNotifier extends StateNotifier<ConversationState> {
  final ConversationRepository _repository;
  Timer? _updateTimer;
  final Map<String, ConversationModel> _pendingUpdates = {};

  ConversationNotifier(this._repository) : super(const ConversationState()) {
    _setupSocketListeners();
  }

  /// Load conversations from the server
  Future<void> loadConversations() async {
    if (state.isLoading) return;

    print('💬 Loading conversations...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final conversations = await _repository.getConversations();
      print('📋 Loaded ${conversations.length} conversations');

      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print('❌ Error loading conversations: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh conversations
  Future<void> refreshConversations() async {
    await loadConversations();
  }

  /// Mark a conversation as read
  Future<void> markConversationAsRead(String chatId) async {
    try {
      await _repository.markConversationAsRead(chatId);

      // Update local state immediately
      final updatedConversations = state.conversations.map((conversation) {
        if (conversation.id == chatId) {
          return conversation.copyWith(unreadCount: 0);
        }
        return conversation;
      }).toList();

      state = state.copyWith(conversations: updatedConversations);
      print('✅ Conversation marked as read locally: $chatId');
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
    }
  }

  /// Update conversation when a new message arrives (with throttling)
  void updateConversationFromMessage(Map<String, dynamic> messageData) {
    final chatId = messageData['chatId'] as String?;
    final messageText = messageData['text'] as String?;
    final senderId = messageData['sender'] as String?;
    final messageType = messageData['type'] as String?;
    final timestamp = messageData['timestamp'] != null 
        ? DateTime.tryParse(messageData['timestamp'] as String) ?? DateTime.now()
        : DateTime.now();

    if (chatId == null) return;

    // Find the conversation to update
    final conversationIndex = state.conversations.indexWhere((c) => c.id == chatId);
    if (conversationIndex == -1) return;

    final conversation = state.conversations[conversationIndex];
    final updatedConversation = conversation.copyWith(
      lastMessageText: messageText,
      lastMessageTimestamp: timestamp, // Use actual message timestamp
      lastMessageSender: senderId != null
          ? conversation.participants.firstWhere(
              (p) => p.id == senderId,
              orElse: () => conversation.participants.first,
            )
          : null,
      lastMessageType: _parseMessageType(messageType),
      unreadCount: conversation.unreadCount + 1,
    );

    // Store the update for batching
    _pendingUpdates[chatId] = updatedConversation;
    
    // Throttle updates to prevent rapid UI changes
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 300), () {
      _applyPendingUpdates();
    });

    print('🔄 Scheduled conversation update for: $chatId');
  }

  /// Apply all pending conversation updates at once
  void _applyPendingUpdates() {
    if (_pendingUpdates.isEmpty) return;

    final updatedConversations = state.conversations.map((conversation) {
      if (_pendingUpdates.containsKey(conversation.id)) {
        return _pendingUpdates[conversation.id]!;
      }
      return conversation;
    }).toList();

    state = state.copyWith(conversations: updatedConversations);
    _pendingUpdates.clear();
    print('✅ Applied ${_pendingUpdates.length} pending conversation updates');
  }

  /// Update conversation from socket event (with throttling)
  void updateConversationFromSocket(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final lastMessage = data['lastMessage'] as Map<String, dynamic>?;
    final unreadCount = data['unreadCount'] as int?;

    if (chatId == null) return;

    // Find the conversation to update
    final conversationIndex = state.conversations.indexWhere((c) => c.id == chatId);
    if (conversationIndex == -1) return;

    final conversation = state.conversations[conversationIndex];
    final updatedConversation = conversation.copyWith(
      lastMessageText: lastMessage?['text'] as String?,
      lastMessageTimestamp: lastMessage?['timestamp'] != null
          ? DateTime.parse(lastMessage!['timestamp'] as String)
          : conversation.lastMessageTimestamp,
      lastMessageType: _parseMessageType(lastMessage?['type'] as String?),
      unreadCount: unreadCount ?? conversation.unreadCount,
    );

    // Store the update for batching
    _pendingUpdates[chatId] = updatedConversation;
    
    // Throttle updates to prevent rapid UI changes
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(milliseconds: 300), () {
      _applyPendingUpdates();
    });

    print('🔄 Scheduled socket conversation update for: $chatId');
  }

  /// Handle conversation read event
  void handleConversationRead(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final userId = data['userId'] as String?;

    if (chatId == null) return;

    final updatedConversations = state.conversations.map((conversation) {
      if (conversation.id == chatId) {
        return conversation.copyWith(unreadCount: 0);
      }
      return conversation;
    }).toList();

    state = state.copyWith(conversations: updatedConversations);
    print('📖 Conversation read: $chatId by $userId');
  }

  /// Add a new conversation
  void addConversation(ConversationModel conversation) {
    final existingIndex = state.conversations.indexWhere(
      (c) => c.id == conversation.id,
    );

    final updatedConversations = List<ConversationModel>.from(
      state.conversations,
    );

    if (existingIndex != -1) {
      updatedConversations[existingIndex] = conversation;
    } else {
      updatedConversations.insert(0, conversation);
    }

    state = state.copyWith(conversations: updatedConversations);
    print('➕ Added/Updated conversation: ${conversation.id}');
  }

  /// Remove a conversation
  void removeConversation(String chatId) {
    final updatedConversations = state.conversations
        .where((c) => c.id != chatId)
        .toList();
    state = state.copyWith(conversations: updatedConversations);
    print('➖ Removed conversation: $chatId');
  }

  /// Setup socket listeners for real-time updates
  void _setupSocketListeners() {
    // Listen for new messages
    SocketService.instance.on('messageReceived', (data) {
      print('📨 Socket: New message received');
      if (data is Map<String, dynamic>) {
        updateConversationFromMessage(data);
      }
    });

    // Listen for conversation updates
    SocketService.instance.on('conversationUpdated', (data) {
      print('🔄 Socket: Conversation updated');
      if (data is Map<String, dynamic>) {
        updateConversationFromSocket(data);
      }
    });

    // Listen for conversation read events
    SocketService.instance.on('conversationRead', (data) {
      print('📖 Socket: Conversation read');
      if (data is Map<String, dynamic>) {
        handleConversationRead(data);
      }
    });

    // Listen for new chat events
    SocketService.instance.on('newChatEvent', (data) {
      print('➕ Socket: New chat event');
      if (data is Map<String, dynamic>) {
        try {
          final conversation = ConversationModel.fromJson(data);
          addConversation(conversation);
        } catch (e) {
          print('❌ Error parsing new chat event: $e');
        }
      }
    });

    // Listen for chat deletion events
    SocketService.instance.on('leaveChat', (data) {
      print('➖ Socket: Leave chat event');
      if (data is Map<String, dynamic>) {
        final chatId = data['_id'] as String?;
        if (chatId != null) {
          removeConversation(chatId);
        }
      }
    });
  }

  /// Parse message type from string
  MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text;

    switch (typeString.toLowerCase()) {
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

  @override
  void dispose() {
    // Clean up timer and pending updates
    _updateTimer?.cancel();
    _pendingUpdates.clear();
    // Clean up socket listeners if needed
    super.dispose();
  }
}
