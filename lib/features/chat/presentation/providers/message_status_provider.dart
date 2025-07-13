import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/socket_service.dart';
import 'message_provider.dart';

/// Provider for managing message status updates
final messageStatusProvider =
    StateNotifierProvider<MessageStatusNotifier, MessageStatusState>((ref) {
      return MessageStatusNotifier();
    });

/// State class for message status
class MessageStatusState {
  final Map<String, MessageModel> messages;
  final Map<String, MessageStatus> statusUpdates;
  final Map<String, List<String>> readByUpdates;
  final Map<String, List<String>> deliveredToUpdates;
  final Set<String> retryingMessages;

  const MessageStatusState({
    this.messages = const {},
    this.statusUpdates = const {},
    this.readByUpdates = const {},
    this.deliveredToUpdates = const {},
    this.retryingMessages = const {},
  });

  MessageStatusState copyWith({
    Map<String, MessageModel>? messages,
    Map<String, MessageStatus>? statusUpdates,
    Map<String, List<String>>? readByUpdates,
    Map<String, List<String>>? deliveredToUpdates,
    Set<String>? retryingMessages,
  }) {
    return MessageStatusState(
      messages: messages ?? this.messages,
      statusUpdates: statusUpdates ?? this.statusUpdates,
      readByUpdates: readByUpdates ?? this.readByUpdates,
      deliveredToUpdates: deliveredToUpdates ?? this.deliveredToUpdates,
      retryingMessages: retryingMessages ?? this.retryingMessages,
    );
  }

  /// Get message with latest status
  MessageModel? getMessageWithStatus(String messageId) {
    final message = messages[messageId];
    if (message == null) return null;

    final latestStatus = statusUpdates[messageId];
    final latestReadBy = readByUpdates[messageId];
    final latestDeliveredTo = deliveredToUpdates[messageId];

    if (latestStatus == null &&
        latestReadBy == null &&
        latestDeliveredTo == null) {
      return message;
    }

    return message.copyWith(
      status: latestStatus ?? message.status,
      readBy: latestReadBy ?? message.readBy,
      deliveredTo: latestDeliveredTo ?? message.deliveredTo,
    );
  }

  /// Check if message is being retried
  bool isRetrying(String messageId) {
    return retryingMessages.contains(messageId);
  }
}

/// Notifier for managing message status
class MessageStatusNotifier extends StateNotifier<MessageStatusState> {
  MessageStatusNotifier() : super(const MessageStatusState()) {
    _initializeSocketListeners();
  }

  StreamSubscription? _statusUpdateSubscription;
  StreamSubscription? _deliveredSubscription;
  StreamSubscription? _readSubscription;
  StreamSubscription? _sentSubscription;
  StreamSubscription? _failedSubscription;

  void _initializeSocketListeners() {
    final socketService = SocketService.instance;

    // Listen to message status updates
    _statusUpdateSubscription = socketService.messageStatusUpdateStream.listen((
      data,
    ) {
      _handleStatusUpdate(data);
    });

    // Listen to message delivered events
    _deliveredSubscription = socketService.messageDeliveredStream.listen((
      data,
    ) {
      _handleMessageDelivered(data);
    });

    // Listen to message read events
    _readSubscription = socketService.messageReadStream.listen((data) {
      _handleMessageRead(data);
    });

    // Listen to message sent confirmations
    _sentSubscription = socketService.messageSentStream.listen((data) {
      _handleMessageSent(data);
    });

    // Listen to message failed events
    _failedSubscription = socketService.messageFailedStream.listen((data) {
      _handleMessageFailed(data);
    });
  }

  /// Add or update a message in the state
  void updateMessage(MessageModel message) {
    state = state.copyWith(messages: {...state.messages, message.id: message});
  }

  /// Handle status update from socket
  void _handleStatusUpdate(Map<String, dynamic> data) {
    try {
      debugPrint(
        '🔍 MessageStatusProvider: Received status update event: $data',
      );

      final messageId = data['messageId'] as String?;
      final statusString = data['status'] as String?;

      if (messageId == null || statusString == null) {
        debugPrint(
          '❌ MessageStatusProvider: Missing messageId or status in update event',
        );
        return;
      }

      final status = _parseMessageStatus(statusString);

      debugPrint(
        '📊 MessageStatusProvider: Processing status update: $messageId -> $status',
      );

      // Update status
      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      newStatusUpdates[messageId] = status;

      // Update read/delivered arrays if provided
      Map<String, List<String>>? newReadByUpdates;
      Map<String, List<String>>? newDeliveredToUpdates;

      if (data['readBy'] != null) {
        newReadByUpdates = Map<String, List<String>>.from(state.readByUpdates);
        newReadByUpdates[messageId] = List<String>.from(data['readBy']);
      }

      if (data['deliveredTo'] != null) {
        newDeliveredToUpdates = Map<String, List<String>>.from(
          state.deliveredToUpdates,
        );
        newDeliveredToUpdates[messageId] = List<String>.from(
          data['deliveredTo'],
        );
      }

      state = state.copyWith(
        statusUpdates: newStatusUpdates,
        readByUpdates: newReadByUpdates,
        deliveredToUpdates: newDeliveredToUpdates,
      );

      // Remove from retrying if successful
      if (status != MessageStatus.failed && status != MessageStatus.pending) {
        _removeFromRetrying(messageId);
      }
    } catch (e) {
      debugPrint('❌ Error handling status update: $e');
    }
  }

  /// Handle message delivered event
  void _handleMessageDelivered(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'] as String?;
      final deliveredTo = data['deliveredTo'] as String?;

      if (messageId == null || deliveredTo == null) return;

      debugPrint('📬 Message delivered: $messageId to $deliveredTo');

      final newDeliveredToUpdates = Map<String, List<String>>.from(
        state.deliveredToUpdates,
      );
      final currentList = newDeliveredToUpdates[messageId] ?? [];

      if (!currentList.contains(deliveredTo)) {
        newDeliveredToUpdates[messageId] = [...currentList, deliveredTo];
        debugPrint(
          '✅ MessageStatusProvider: Updated deliveredTo for $messageId: ${[...currentList, deliveredTo]}',
        );
      }

      // Also update the message status to delivered if not already read
      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      final currentStatus = newStatusUpdates[messageId];
      if (currentStatus != MessageStatus.read) {
        newStatusUpdates[messageId] = MessageStatus.delivered;
        debugPrint(
          '🔄 MessageStatusProvider: Updated message status to delivered for $messageId',
        );
      }

      state = state.copyWith(
        deliveredToUpdates: newDeliveredToUpdates,
        statusUpdates: newStatusUpdates,
      );

      debugPrint(
        '✅ MessageStatusProvider: Delivered event processed successfully for $messageId',
      );
    } catch (e) {
      debugPrint('❌ Error handling message delivered: $e');
    }
  }

  /// Handle message read event
  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      debugPrint(
        '🔍 MessageStatusProvider: Received message read event: $data',
      );

      final messageId = data['messageId'] as String?;
      final readBy = data['readBy'] as String?;

      if (messageId == null || readBy == null) {
        debugPrint(
          '❌ MessageStatusProvider: Missing messageId or readBy in read event',
        );
        return;
      }

      debugPrint(
        '📖 MessageStatusProvider: Processing message read: $messageId by $readBy',
      );

      final newReadByUpdates = Map<String, List<String>>.from(
        state.readByUpdates,
      );
      final currentList = newReadByUpdates[messageId] ?? [];

      if (!currentList.contains(readBy)) {
        newReadByUpdates[messageId] = [...currentList, readBy];
        debugPrint(
          '✅ MessageStatusProvider: Updated readBy for $messageId: ${[...currentList, readBy]}',
        );
      }

      // Also update the message status to read
      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      newStatusUpdates[messageId] = MessageStatus.read;

      debugPrint(
        '🔄 MessageStatusProvider: Updated message status to read for $messageId',
      );

      state = state.copyWith(
        readByUpdates: newReadByUpdates,
        statusUpdates: newStatusUpdates,
      );

      debugPrint(
        '✅ MessageStatusProvider: Read event processed successfully for $messageId',
      );
    } catch (e) {
      debugPrint('❌ Error handling message read: $e');
    }
  }

  /// Handle message sent confirmation
  void _handleMessageSent(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'] as String?;

      if (messageId == null) return;

      debugPrint('📤 Message sent confirmation: $messageId');

      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      newStatusUpdates[messageId] = MessageStatus.sent;

      state = state.copyWith(statusUpdates: newStatusUpdates);

      _removeFromRetrying(messageId);
    } catch (e) {
      debugPrint('❌ Error handling message sent: $e');
    }
  }

  /// Handle message failed event
  void _handleMessageFailed(Map<String, dynamic> data) {
    try {
      final messageId = data['messageId'] as String?;

      if (messageId == null) return;

      debugPrint('❌ Message failed: $messageId');

      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      newStatusUpdates[messageId] = MessageStatus.failed;

      state = state.copyWith(statusUpdates: newStatusUpdates);

      _removeFromRetrying(messageId);
    } catch (e) {
      debugPrint('❌ Error handling message failed: $e');
    }
  }

  /// Retry a failed message
  Future<void> retryMessage(String messageId) async {
    try {
      debugPrint('🔄 Retrying message: $messageId');

      // Add to retrying set
      final newRetryingMessages = Set<String>.from(state.retryingMessages);
      newRetryingMessages.add(messageId);

      // Update status to pending
      final newStatusUpdates = Map<String, MessageStatus>.from(
        state.statusUpdates,
      );
      newStatusUpdates[messageId] = MessageStatus.pending;

      state = state.copyWith(
        retryingMessages: newRetryingMessages,
        statusUpdates: newStatusUpdates,
      );

      // Emit retry event through socket
      SocketService.instance.retryMessage(messageId);

      // Set timeout for retry
      Timer(const Duration(seconds: 30), () {
        if (state.retryingMessages.contains(messageId)) {
          _removeFromRetrying(messageId);

          // Mark as failed if still retrying after timeout
          final currentStatus = state.statusUpdates[messageId];
          if (currentStatus == MessageStatus.pending ||
              currentStatus == MessageStatus.sending) {
            final newStatusUpdates = Map<String, MessageStatus>.from(
              state.statusUpdates,
            );
            newStatusUpdates[messageId] = MessageStatus.failed;

            state = state.copyWith(statusUpdates: newStatusUpdates);
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error retrying message: $e');
      _removeFromRetrying(messageId);
    }
  }

  /// Mark message as read
  void markAsRead(String messageId, {String? chatId}) {
    debugPrint(
      '🔍 MessageStatusProvider: markAsRead called for message: $messageId, chatId: $chatId',
    );
    SocketService.instance.markMessageAsRead(messageId, chatId: chatId);
  }

  /// Mark message as delivered
  void markAsDelivered(String messageId, {String? chatId}) {
    SocketService.instance.markMessageAsDelivered(messageId, chatId: chatId);
  }

  /// Remove message from retrying set
  void _removeFromRetrying(String messageId) {
    final newRetryingMessages = Set<String>.from(state.retryingMessages);
    newRetryingMessages.remove(messageId);

    state = state.copyWith(retryingMessages: newRetryingMessages);
  }

  /// Parse message status from string
  MessageStatus _parseMessageStatus(String statusString) {
    switch (statusString.toLowerCase()) {
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

  /// Clear all status data
  void clear() {
    state = const MessageStatusState();
  }

  @override
  void dispose() {
    _statusUpdateSubscription?.cancel();
    _deliveredSubscription?.cancel();
    _readSubscription?.cancel();
    _sentSubscription?.cancel();
    _failedSubscription?.cancel();
    super.dispose();
  }
}

/// Provider to get message with latest status
final messageWithStatusProvider = Provider.family<MessageModel?, String>((
  ref,
  messageId,
) {
  final statusState = ref.watch(messageStatusProvider);
  final messageState = ref.watch(messageProvider);

  // First try to get the message with status from the status provider
  final messageWithStatus = statusState.getMessageWithStatus(messageId);
  if (messageWithStatus != null) {
    return messageWithStatus;
  }

  // If not found in status provider, find the original message and apply any status updates
  MessageModel? originalMessage;
  for (final messages in messageState.messagesByChat.values) {
    final found = messages.where((msg) => msg.id == messageId).firstOrNull;
    if (found != null) {
      originalMessage = found;
      break;
    }
  }

  if (originalMessage == null) return null;

  // Apply any status updates from the status provider
  final latestStatus = statusState.statusUpdates[messageId];
  final latestReadBy = statusState.readByUpdates[messageId];
  final latestDeliveredTo = statusState.deliveredToUpdates[messageId];

  if (latestStatus == null &&
      latestReadBy == null &&
      latestDeliveredTo == null) {
    return originalMessage;
  }

  return originalMessage.copyWith(
    status: latestStatus ?? originalMessage.status,
    readBy: latestReadBy ?? originalMessage.readBy,
    deliveredTo: latestDeliveredTo ?? originalMessage.deliveredTo,
  );
});

/// Provider to check if message is being retried
final messageRetryingProvider = Provider.family<bool, String>((ref, messageId) {
  final statusState = ref.watch(messageStatusProvider);
  return statusState.isRetrying(messageId);
});
