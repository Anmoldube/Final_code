import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Service to handle offline functionality and sync
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Stream controller for connectivity changes
  final _connectivityStreamController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;

  // Initialize the service
  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final firstResult = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _handleConnectivityChange(firstResult);
    });
  }

  // Check current connectivity
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Handle the list of connectivity results
      final firstResult = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _handleConnectivityChange(firstResult);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      _connectivityStreamController.add(_isOnline);
    }
  }

  // Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    // Only notify if state changed
    if (wasOnline != _isOnline) {
      _connectivityStreamController.add(_isOnline);

      // If we're back online, trigger sync
      if (_isOnline) {
        syncOfflineData();
      }
    }
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }

  // Save a message locally when offline
  Future<MessageModel> saveOfflineMessage(MessageModel message) async {
    // Mark as not synced and local only
    final offlineMessage = message.copyWith(
      isSynced: false,
      isLocalOnly: true,
      localId:
          'local_${DateTime.now().millisecondsSinceEpoch}_${message.chatId}',
      lastSyncedAt: DateTime.now(),
    );

    // Save to local storage
    final messages = StorageService.getMessages(message.chatId) ?? [];
    messages.add(offlineMessage.toJson());
    await StorageService.saveMessages(message.chatId, messages);

    return offlineMessage;
  }

  // Save a chat locally when offline
  Future<ChatModel> saveOfflineChat(ChatModel chat) async {
    // Mark as not synced and local only
    final offlineChat = chat.copyWith(
      isSynced: false,
      isLocalOnly: true,
      lastSyncedAt: DateTime.now(),
    );

    // Save to local storage
    final chats = StorageService.getChatsList() ?? [];
    chats.add(offlineChat.toJson());
    await StorageService.saveChatsList(chats);

    return offlineChat;
  }

  // Update user status locally when offline
  Future<UserModel> saveOfflineUserStatus(UserModel user) async {
    // Mark as not synced
    final offlineUser = user.copyWith(
      isSynced: false,
      lastSyncedAt: DateTime.now(),
    );

    // Save to local storage
    await StorageService.saveUserData(offlineUser.toJson());

    return offlineUser;
  }

  // Get all unsynchronized messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final result = <MessageModel>[];

    // Get all chat IDs
    final chats = StorageService.getChatsList() ?? [];

    // For each chat, get messages
    for (final chatData in chats) {
      final chatId = chatData['_id']?.toString() ?? '';
      if (chatId.isEmpty) continue;

      final messages = StorageService.getMessages(chatId) ?? [];

      // Filter for unsynced messages
      for (final messageData in messages) {
        if (messageData['isSynced'] == false) {
          try {
            final message = MessageModel.fromJson(messageData);
            result.add(message);
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        }
      }
    }

    return result;
  }

  // Get all unsynchronized chats
  Future<List<ChatModel>> getUnsyncedChats() async {
    final result = <ChatModel>[];

    // Get all chats
    final chats = StorageService.getChatsList() ?? [];

    // Filter for unsynced chats
    for (final chatData in chats) {
      if (chatData['isSynced'] == false) {
        try {
          final chat = ChatModel.fromJson(chatData);
          result.add(chat);
        } catch (e) {
          debugPrint('Error parsing chat: $e');
        }
      }
    }

    return result;
  }

  // Sync all offline data when back online
  Future<void> syncOfflineData() async {
    if (!_isOnline) return;

    debugPrint('🔄 Syncing offline data...');

    // Sync messages
    final unsyncedMessages = await getUnsyncedMessages();
    debugPrint('📝 Found ${unsyncedMessages.length} unsynced messages');

    // TODO: Implement actual API calls to sync messages
    // For now, just mark them as synced
    for (final message in unsyncedMessages) {
      await _markMessageAsSynced(message);
    }

    // Sync chats
    final unsyncedChats = await getUnsyncedChats();
    debugPrint('💬 Found ${unsyncedChats.length} unsynced chats');

    // TODO: Implement actual API calls to sync chats
    // For now, just mark them as synced
    for (final chat in unsyncedChats) {
      await _markChatAsSynced(chat);
    }

    // Sync user data
    final userData = StorageService.getUserData();
    if (userData != null && userData['isSynced'] == false) {
      debugPrint('👤 Found unsynced user data');

      // TODO: Implement actual API call to sync user data
      // For now, just mark it as synced
      userData['isSynced'] = true;
      userData['lastSyncedAt'] = DateTime.now().toIso8601String();
      await StorageService.saveUserData(userData);
    }

    debugPrint('✅ Offline data sync completed');
  }

  // Mark a message as synced
  Future<void> _markMessageAsSynced(MessageModel message) async {
    final messages = StorageService.getMessages(message.chatId) ?? [];

    // Find and update the message
    for (int i = 0; i < messages.length; i++) {
      final id = messages[i]['_id']?.toString() ?? '';
      final localId = messages[i]['localId']?.toString() ?? '';

      if (id == message.id ||
          (localId.isNotEmpty && localId == message.localId)) {
        messages[i]['isSynced'] = true;
        messages[i]['lastSyncedAt'] = DateTime.now().toIso8601String();
        break;
      }
    }

    // Save updated messages
    await StorageService.saveMessages(message.chatId, messages);
  }

  // Mark a chat as synced
  Future<void> _markChatAsSynced(ChatModel chat) async {
    final chats = StorageService.getChatsList() ?? [];

    // Find and update the chat
    for (int i = 0; i < chats.length; i++) {
      final id = chats[i]['_id']?.toString() ?? '';

      if (id == chat.id) {
        chats[i]['isSynced'] = true;
        chats[i]['lastSyncedAt'] = DateTime.now().toIso8601String();
        break;
      }
    }

    // Save updated chats
    await StorageService.saveChatsList(chats);
  }
}
