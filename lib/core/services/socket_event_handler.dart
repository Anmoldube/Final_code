import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/chat/presentation/providers/chat_provider.dart';
import '../../features/chat/presentation/providers/message_provider.dart';
import '../../features/chat/presentation/providers/message_status_provider.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'socket_service.dart';

class SocketEventHandler {
  static SocketEventHandler? _instance;
  static SocketEventHandler get instance =>
      _instance ??= SocketEventHandler._();

  SocketEventHandler._();

  final List<StreamSubscription> _subscriptions = [];
  WidgetRef? _ref;

  void initialize(WidgetRef ref) {
    _ref = ref;
    _setupEventListeners();
  }

  void _setupEventListeners() {
    if (_ref == null) return;

    // Listen to chat update events
    _subscriptions.add(
      SocketService.instance.chatUpdateStream.listen(
        (ChatModel chat) {
          debugPrint(
            '🔄 SocketEventHandler: Received chat update for ${chat.name}',
          );
          _handleNewChat(chat);
        },
        onError: (error) {
          debugPrint('❌ SocketEventHandler: Chat update stream error: $error');
        },
      ),
    );

    // Listen to message events
    _subscriptions.add(
      SocketService.instance.messageStream.listen(
        (MessageModel message) {
          debugPrint(
            '🔄 SocketEventHandler: Received message for chat ${message.chatId}',
          );
          _handleNewMessage(message);
        },
        onError: (error) {
          debugPrint('❌ SocketEventHandler: Message stream error: $error');
        },
      ),
    );

    // Listen to typing events
    _subscriptions.add(
      SocketService.instance.typingStream.listen(
        (Map<String, dynamic> typingData) {
          debugPrint(
            '🔄 SocketEventHandler: Received typing event: $typingData',
          );
          _handleTypingEvent(typingData);
        },
        onError: (error) {
          debugPrint('❌ SocketEventHandler: Typing stream error: $error');
        },
      ),
    );
    debugPrint('✅ SocketEventHandler: Event listeners initialized');
  }

  void _handleNewChat(ChatModel chat) {
    if (_ref == null) return;

    try {
      // Add the new chat to the chat provider
      final chatNotifier = _ref!.read(chatProvider.notifier);

      // Get current chats and add the new one if it doesn't exist
      final currentChats = _ref!.read(chatProvider).chats;
      final existingChatIndex = currentChats.indexWhere((c) => c.id == chat.id);

      if (existingChatIndex == -1) {
        // This is a new chat, add it to the list
        debugPrint('✅ SocketEventHandler: Adding new chat: ${chat.name}');
        chatNotifier.addNewChat(chat);
      } else {
        // This is an update to an existing chat
        debugPrint(
          '✅ SocketEventHandler: Updating existing chat: ${chat.name}',
        );
        chatNotifier.updateChat(chat);
      }
    } catch (e) {
      debugPrint('❌ SocketEventHandler: Error handling new chat: $e');
    }
  }

  void _handleNewMessage(MessageModel message) {
    if (_ref == null) return;

    try {
      final currentUser = _ref!.read(currentUserProvider);
      
      // Skip processing if this message is from the current user
      // (to avoid duplicates from optimistic updates)
      if (currentUser != null && message.sender.id == currentUser.id) {
        debugPrint('🔍 SocketEventHandler: Skipping own message to avoid duplication: ${message.id}');
        return;
      }

      // Add the message to the message provider
      final messageNotifier = _ref!.read(messageProvider.notifier);
      messageNotifier.addReceivedMessage(message);

      // Update the chat's last message
      final chatNotifier = _ref!.read(chatProvider.notifier);
      chatNotifier.updateChatLastMessage(message.chatId, message);

      // Automatically mark message as delivered if it's not from current user
      final messageStatusNotifier = _ref!.read(
        messageStatusProvider.notifier,
      );
      messageStatusNotifier.markAsDelivered(
        message.id,
        chatId: message.chatId,
      );
      debugPrint(
        '📬 SocketEventHandler: Marked message as delivered: ${message.id}',
      );

      debugPrint(
        '✅ SocketEventHandler: Added new message to chat ${message.chatId}',
      );
    } catch (e) {
      debugPrint('❌ SocketEventHandler: Error handling new message: $e');
    }
  }

  void _handleTypingEvent(Map<String, dynamic> typingData) {
    if (_ref == null) return;

    try {
      final messageNotifier = _ref!.read(messageProvider.notifier);

      if (typingData['type'] == 'typing') {
        messageNotifier.addTypingUser(
          typingData['chatId'],
          typingData['userId'],
          typingData['userName'] ?? 'Unknown User',
        );
      } else if (typingData['type'] == 'stopped') {
        messageNotifier.removeTypingUser(
          typingData['chatId'],
          typingData['userId'],
        );
      }

      debugPrint(
        '✅ SocketEventHandler: Updated typing status for chat ${typingData['chatId']}',
      );
    } catch (e) {
      debugPrint('❌ SocketEventHandler: Error handling typing event: $e');
    }
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _ref = null;
    debugPrint('✅ SocketEventHandler: Disposed');
  }
}
