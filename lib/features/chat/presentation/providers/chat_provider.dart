import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/chat_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/repositories/chat_repository.dart';
import '../states/chat_state.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.read(chatRepositoryProvider));
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _chatRepository;

  ChatNotifier(this._chatRepository) : super(const ChatState()) {
    _listenToNewChats();
  }

  // Listen to new chats from socket
  void _listenToNewChats() {
    SocketService.instance.chatUpdateStream.listen((newChat) {
      debugPrint('🔄 ChatProvider: Received new chat from socket: ${newChat.name}');
      addNewChat(newChat);
    });
  }

  // Load all chats
  Future<void> loadChats() async {
    if (state.isLoading) return;

    print('💬 Loading chats...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final chats = await _chatRepository.getAllChats();
      print('📋 Loaded ${chats.length} chats from repository');

      _organizeChatsByType(chats);
      state = state.copyWith(isLoading: false);

      // Auto-join all loaded chats via socket
      final chatIds = chats.map((chat) => chat.id).toList();
      SocketService.instance.joinMultipleChats(chatIds);

      print(
        '✅ Chats loaded: ${state.directChats.length} direct, ${state.groupChats.length} groups',
      );
    } catch (e, stackTrace) {
      print('❌ Load chats error: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Search chats
  Future<void> searchChats(String query) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    try {
      final searchResults = await _chatRepository.searchChats(query);
      state = state.copyWith(searchResults: searchResults);
    } catch (e) {
      debugPrint('Search chats error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  // Create a new one-on-one chat
  Future<ChatModel?> createDirectChat(String userId) async {
    try {
      final chat = await _chatRepository.createOrGetDirectChat(userId);

      // Add to state if not already present
      final updatedChats = List<ChatModel>.from(state.chats);
      final existingIndex = updatedChats.indexWhere((c) => c.id == chat.id);

      if (existingIndex != -1) {
        updatedChats[existingIndex] = chat;
      } else {
        updatedChats.insert(0, chat);
      }

      _organizeChatsByType(updatedChats);

      return chat;
    } catch (e) {
      debugPrint('Create direct chat error: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Create a new group chat
  Future<ChatModel?> createGroupChat({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    try {
      final chat = await _chatRepository.createGroupChat(
        name: name,
        description: description,
        participantIds: participantIds,
      );

      // Add to state
      final updatedChats = [chat, ...state.chats];
      final directChats = updatedChats
          .where((c) => c.type == ChatType.oneOnOne)
          .toList();
      final groupChats = updatedChats
          .where((c) => c.type == ChatType.group)
          .toList();

      state = state.copyWith(
        chats: updatedChats,
        directChats: directChats,
        groupChats: groupChats,
      );

      return chat;
    } catch (e) {
      debugPrint('Create group chat error: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Update chat (for last message, unread count, etc.)
  void updateChat(ChatModel updatedChat) {
    final updatedChats = state.chats.map((chat) {
      return chat.id == updatedChat.id ? updatedChat : chat;
    }).toList();

    _organizeChatsByType(updatedChats);
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatRepository.deleteChat(chatId);

      final updatedChats = state.chats
          .where((chat) => chat.id != chatId)
          .toList();
      final directChats = updatedChats
          .where((c) => c.type == ChatType.oneOnOne)
          .toList();
      final groupChats = updatedChats
          .where((c) => c.type == ChatType.group)
          .toList();

      state = state.copyWith(
        chats: updatedChats,
        directChats: directChats,
        groupChats: groupChats,
      );
    } catch (e) {
      debugPrint('Delete chat error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Get available users for chat creation
  Future<void> getAvailableUsers({String? query}) async {
    try {
      print('🔄 ChatProvider: Getting available users with query: "$query"');
      final users = await _chatRepository.getAvailableUsers(query: query);
      print('✅ ChatProvider: Received ${users.length} users from repository');
      state = state.copyWith(availableUsers: users);
    } catch (e) {
      print('❌ ChatProvider: Get available users error: $e');
      debugPrint('Get available users error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Create or get existing direct chat
  Future<ChatModel?> createOrGetDirectChat(String userId) async {
    try {
      final chat = await _chatRepository.createOrGetDirectChat(userId);

      // Add to state if not already present
      final updatedChats = List<ChatModel>.from(state.chats);
      final existingIndex = updatedChats.indexWhere((c) => c.id == chat.id);

      if (existingIndex != -1) {
        updatedChats[existingIndex] = chat;
      } else {
        updatedChats.insert(0, chat);
      }

      final directChats = updatedChats
          .where((c) => c.type == ChatType.oneOnOne)
          .toList();
      final groupChats = updatedChats
          .where((c) => c.type == ChatType.group)
          .toList();

      state = state.copyWith(
        chats: updatedChats,
        directChats: directChats,
        groupChats: groupChats,
      );

      return chat;
    } catch (e) {
      debugPrint('Create or get direct chat error: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Add user to group chat
  Future<void> addUserToGroup(String chatId, String userId) async {
    try {
      final updatedChat = await _chatRepository.addUserToGroup(chatId, userId);
      updateChat(updatedChat);
    } catch (e) {
      debugPrint('Add user to group error: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _chatRepository.markChatAsRead(chatId);

      // Update local state
      final updatedChats = state.chats.map((chat) {
        if (chat.id == chatId) {
          return chat.copyWith(unreadCount: 0);
        }
        return chat;
      }).toList();

      final directChats = updatedChats
          .where((c) => c.type == ChatType.oneOnOne)
          .toList();
      final groupChats = updatedChats
          .where((c) => c.type == ChatType.group)
          .toList();

      state = state.copyWith(
        chats: updatedChats,
        directChats: directChats,
        groupChats: groupChats,
      );
    } catch (e) {
      debugPrint('Mark chat as read error: $e');
    }
  }

  // Get chat by ID
  ChatModel? getChatById(String chatId) {
    try {
      return state.chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  // Refresh chats
  Future<void> refreshChats() async {
    await loadChats();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get total unread count
  int get totalUnreadCount {
    return state.chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  // Get chats with unread messages
  List<ChatModel> get chatsWithUnreadMessages {
    return state.chats.where((chat) => chat.unreadCount > 0).toList();
  }

  // Helper method to sort chats by last message time
  List<ChatModel> _sortChatsByLastMessage(List<ChatModel> chats) {
    return chats..sort((a, b) {
      // Sort by last message time (most recent first)
      if (a.lastMessage != null && b.lastMessage != null) {
        return b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt);
      } else if (a.lastMessage != null) {
        return -1;
      } else if (b.lastMessage != null) {
        return 1;
      }
      // If no messages, sort by creation time
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Add a new chat received from socket
  void addNewChat(ChatModel chat) {
    final updatedChats = [chat, ...state.chats];
    _organizeChatsByType(updatedChats);
    debugPrint('✅ ChatProvider: Added new chat: ${chat.name}');
  }

  // Update chat last message
  void updateChatLastMessage(String chatId, MessageModel message) {
    final updatedChats = state.chats.map((chat) {
      if (chat.id == chatId) {
        return chat.copyWith(
          lastMessage: message,
          unreadCount: chat.unreadCount + 1,
        );
      }
      return chat;
    }).toList();

    _organizeChatsByType(updatedChats);
    debugPrint('✅ ChatProvider: Updated last message for chat: $chatId');
  }

  // Helper method to organize chats by type with sorting
  void _organizeChatsByType(List<ChatModel> chats) {
    final directChats = _sortChatsByLastMessage(
      chats.where((chat) => chat.type == ChatType.oneOnOne).toList()
    );
    
    // Separate default groups from regular groups
    final allGroupChats = chats.where((chat) => chat.type == ChatType.group).toList();
    final defaultGroups = allGroupChats.where((chat) => chat.isDefault).toList();
    final regularGroups = allGroupChats.where((chat) => !chat.isDefault).toList();
    
    // Sort regular groups by last message, but keep default groups at the top
    final sortedRegularGroups = _sortChatsByLastMessage(regularGroups);
    final sortedDefaultGroups = _sortChatsByLastMessage(defaultGroups);
    
    // Combine with default groups first
    final groupChats = [...sortedDefaultGroups, ...sortedRegularGroups];

    state = state.copyWith(
      chats: chats,
      directChats: directChats,
      groupChats: groupChats,
    );
  }
}

// Provider for getting a specific chat
final chatByIdProvider = Provider.family<ChatModel?, String>((ref, chatId) {
  final chatState = ref.watch(chatProvider);
  try {
    return chatState.chats.firstWhere((chat) => chat.id == chatId);
  } catch (e) {
    return null;
  }
});

// Provider for total unread count
final totalUnreadCountProvider = Provider<int>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.chats.fold(0, (sum, chat) => sum + chat.unreadCount);
});

// Provider for chats with unread messages
final unreadChatsProvider = Provider<List<ChatModel>>((ref) {
  final chatState = ref.watch(chatProvider);
  return chatState.chats.where((chat) => chat.unreadCount > 0).toList();
});
