import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../config/api_config.dart';

import 'storage_service.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();

  SocketService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;

  // Stream controllers for different events
  final _messageStreamController = StreamController<MessageModel>.broadcast();
  final _typingStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _userStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatUpdateStreamController = StreamController<ChatModel>.broadcast();
  final _connectionStreamController = StreamController<bool>.broadcast();

  // Message status stream controllers
  final _messageStatusUpdateStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeliveredStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageSentStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageFailedStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<MessageModel> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream =>
      _typingStreamController.stream;
  Stream<Map<String, dynamic>> get userStatusStream =>
      _userStatusStreamController.stream;
  Stream<ChatModel> get chatUpdateStream => _chatUpdateStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  // Message status streams
  Stream<Map<String, dynamic>> get messageStatusUpdateStream =>
      _messageStatusUpdateStreamController.stream;
  Stream<Map<String, dynamic>> get messageDeliveredStream =>
      _messageDeliveredStreamController.stream;
  Stream<Map<String, dynamic>> get messageReadStream =>
      _messageReadStreamController.stream;
  Stream<Map<String, dynamic>> get messageSentStream =>
      _messageSentStreamController.stream;
  Stream<Map<String, dynamic>> get messageFailedStream =>
      _messageFailedStreamController.stream;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  String? get socketId => _socket?.id;

  Future<void> connect(String userId) async {
    if (_socket != null && _isConnected) {
      await disconnect();
    }

    _currentUserId = userId;

    try {
      final token = await StorageService.getAccessToken();
      debugPrint('🔌 Socket: Attempting connection for user: $userId');
      debugPrint('🔌 Socket: Token available: ${token != null}');

      if (token == null) {
        debugPrint('❌ Socket: No token available for connection');
        return;
      }

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setExtraHeaders({'authorization': 'Bearer $token'})
            .setAuth({'token': token}) // Also send token in auth
            .setQuery({'userId': userId})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .build(),
      );

      _setupEventListeners();

      // Connect
      _socket?.connect();
      debugPrint('🔌 Socket: Connection initiated');
    } catch (e) {
      debugPrint('❌ Socket connection error: $e');
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('🟢 Socket connected successfully');
      debugPrint('🔗 Socket ID: ${_socket!.id}');
      debugPrint('👤 Current User ID: $_currentUserId');
      _isConnected = true;
      _connectionStreamController.add(true);
    });

    // Listen for successful connection confirmation from server
    _socket!.on('connected', (data) {
      debugPrint('🎉 Server confirmed connection: $data');
      _isConnected = true;
      _connectionStreamController.add(true);
      
      // Automatically join user groups after successful connection
      if (_currentUserId != null) {
        joinUserGroups(_currentUserId!);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    _socket!.onReconnect((_) {
      debugPrint('Socket reconnected');
      _isConnected = true;
      _connectionStreamController.add(true);
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    // Message events - Listen for the correct event name from backend
    _socket!.on('messageReceived', (data) {
      try {
        debugPrint('🔄 Socket: Received messageReceived event');
        debugPrint('🔄 Socket: Raw data: $data');
        debugPrint('🔄 Socket: Data type: ${data.runtimeType}');

        if (data == null) {
          debugPrint('❌ Socket: Received null data for messageReceived');
          return;
        }

        final message = MessageModel.fromJson(data);
        debugPrint(
          '🔄 Socket: Parsed message successfully - ID: ${message.id}',
        );
        debugPrint('🔄 Socket: Message chat: ${message.chatId}');
        debugPrint('🔄 Socket: Message content: ${message.content}');

        _messageStreamController.add(message);
        debugPrint('🔄 Socket: Message added to stream successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ Socket: Error parsing messageReceived: $e');
        debugPrint('❌ Socket: Stack trace: $stackTrace');
        debugPrint('❌ Socket: Raw data that failed: $data');
      }
    });

    // Fallback for old event name
    _socket!.on('newMessage', (data) {
      try {
        debugPrint('🔄 Socket: Received newMessage: $data');
        final message = MessageModel.fromJson(data);
        _messageStreamController.add(message);
      } catch (e) {
        debugPrint('❌ Socket: Error parsing newMessage: $e');
      }
    });

    _socket!.on('messageUpdated', (data) {
      try {
        final message = MessageModel.fromJson(data);
        _messageStreamController.add(message);
      } catch (e) {
        debugPrint('Error parsing updated message: $e');
      }
    });

    _socket!.on('messageDeleted', (data) {
      // Handle message deletion
      debugPrint('Message deleted: $data');
    });

    // Enhanced message status events
    _socket!.on('messageStatusUpdate', (data) {
      try {
        debugPrint('📊 Socket: Message status update: $data');
        _messageStatusUpdateStreamController.add(
          Map<String, dynamic>.from(data),
        );
      } catch (e) {
        debugPrint('❌ Socket: Error parsing message status update: $e');
      }
    });

    _socket!.on('messageDelivered', (data) {
      try {
        debugPrint('📬 Socket: Message delivered: $data');
        _messageDeliveredStreamController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('❌ Socket: Error parsing message delivered: $e');
      }
    });

    _socket!.on('messageRead', (data) {
      try {
        debugPrint('📖 Socket: Message read: $data');
        _messageReadStreamController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('❌ Socket: Error parsing message read: $e');
      }
    });

    _socket!.on('messageSent', (data) {
      try {
        debugPrint('📤 Socket: Message sent confirmation: $data');
        _messageSentStreamController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('❌ Socket: Error parsing message sent: $e');
      }
    });

    _socket!.on('messageFailed', (data) {
      try {
        debugPrint('❌ Socket: Message failed: $data');
        _messageFailedStreamController.add(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('❌ Socket: Error parsing message failed: $e');
      }
    });

    // Typing events
    _socket!.on('userTyping', (data) {
      _typingStreamController.add({
        'type': 'typing',
        'chatId': data['chatId'],
        'userId': data['userId'],
        'userName': data['userName'],
      });
    });

    _socket!.on('userStoppedTyping', (data) {
      _typingStreamController.add({
        'type': 'stopped',
        'chatId': data['chatId'],
        'userId': data['userId'],
      });
    });

    // User status events
    _socket!.on('userOnline', (data) {
      debugPrint('👥 Socket: User online: $data');
      _userStatusStreamController.add({
        'type': 'online',
        'userId': data['userId'],
        'status': data['status'],
        'lastSeen': data['lastSeen'],
        'customStatus': data['customStatus'],
        'isVisible': data['isVisible'],
      });
    });

    _socket!.on('userOffline', (data) {
      debugPrint('👥 Socket: User offline: $data');
      _userStatusStreamController.add({
        'type': 'offline',
        'userId': data['userId'],
        'lastSeen': data['lastSeen'],
      });
    });

    _socket!.on('userStatusChanged', (data) {
      debugPrint('👥 Socket: User status changed: $data');
      _userStatusStreamController.add({
        'type': 'statusChanged',
        'userId': data['userId'],
        'status': data['status'],
        'lastSeen': data['lastSeen'],
        'customStatus': data['customStatus'],
        'isVisible': data['isVisible'],
      });
    });

    // New presence events
    _socket!.on('status:update', (data) {
      debugPrint('🔄 Socket: Received status update: $data');
      _userStatusStreamController.add({
        'type': 'statusUpdate',
        'userId': data['userId'],
        'state': data['state'],
        'lastSeen': data['lastSeen'],
        'customStatus': data['customStatus'],
        'isVisible': data['isVisible'],
      });
    });

    _socket!.on('status:idle', (data) {
      debugPrint('😴 Socket: User idle: $data');
      _userStatusStreamController.add({
        'type': 'idle',
        'userId': data['userId'],
        'lastSeen': data['lastSeen'],
      });
    });

    _socket!.on('status:active', (data) {
      debugPrint('🏃 Socket: User active: $data');
      _userStatusStreamController.add({
        'type': 'online',
        'userId': data['userId'],
        'lastSeen': data['lastSeen'],
      });
    });

    _socket!.on('presence:bulk', (data) {
      debugPrint('📊 Socket: Bulk presence update: $data');
      if (data is List) {
        for (final presenceData in data) {
          _userStatusStreamController.add({
            'type': 'statusUpdate',
            'userId': presenceData['userId'],
            'state': presenceData['state'],
            'lastSeen': presenceData['lastSeen'],
            'customStatus': presenceData['customStatus'],
            'isVisible': presenceData['isVisible'],
          });
        }
      }
    });

    // Chat events - Listen for the correct event name from backend
    _socket!.on('newChatEvent', (data) {
      try {
        debugPrint('🔄 Socket: Received newChatEvent');
        debugPrint('📦 Raw data: $data');
        debugPrint('📦 Data type: ${data.runtimeType}');

        final chat = ChatModel.fromJson(data);
        debugPrint('✅ Parsed chat: ${chat.name} (${chat.id})');
        debugPrint('👥 Participants: ${chat.participants.length}');

        // Automatically join the chat room
        joinChat(chat.id);

        _chatUpdateStreamController.add(chat);
        debugPrint('📢 Added chat to stream controller');
      } catch (e, stackTrace) {
        debugPrint('❌ Socket: Error parsing new chat: $e');
        debugPrint('📚 Stack trace: $stackTrace');
      }
    });

    // Fallback for old event name
    _socket!.on('chatCreated', (data) {
      try {
        debugPrint('🔄 Socket: Received chatCreated: $data');
        final chat = ChatModel.fromJson(data);
        _chatUpdateStreamController.add(chat);
      } catch (e) {
        debugPrint('❌ Socket: Error parsing new chat: $e');
      }
    });

    _socket!.on('chatUpdated', (data) {
      try {
        final chat = ChatModel.fromJson(data);
        _chatUpdateStreamController.add(chat);
      } catch (e) {
        debugPrint('Error parsing updated chat: $e');
      }
    });

    _socket!.on('chatDeleted', (data) {
      debugPrint('Chat deleted: $data');
    });

    // File upload events
    _socket!.on('fileUploadProgress', (data) {
      debugPrint('File upload progress: $data');
    });

    _socket!.on('fileUploadComplete', (data) {
      debugPrint('File upload complete: $data');
    });

    _socket!.on('fileUploadError', (data) {
      debugPrint('File upload error: $data');
    });

    // Listen for test notifications
    _socket!.on('notification', (data) {
      debugPrint('🔔 Test notification received: $data');
    });

    // Listen for user groups joined confirmation
    _socket!.on('user_groups_joined', (data) {
      try {
        debugPrint('🏠 User groups joined confirmation: $data');
        if (data['success'] == true) {
          final groupCount = data['groupCount'] ?? 0;
          final groups = data['groups'] as List<dynamic>? ?? [];
          debugPrint('✅ Successfully joined $groupCount groups');
          
          for (final group in groups) {
            final groupName = group['name'] ?? 'Unknown';
            final isDefault = group['isDefault'] ?? false;
            if (isDefault) {
              debugPrint('🏠 Joined DEFAULT group: $groupName');
            } else {
              debugPrint('📍 Joined group: $groupName');
            }
          }
        } else {
          debugPrint('❌ Failed to join user groups: ${data['error']}');
        }
      } catch (e) {
        debugPrint('❌ Error parsing user_groups_joined: $e');
      }
    });

    // Catch-all event listener for debugging
    _socket!.onAny((event, data) {
      debugPrint('🌐 Socket event received: $event');
      debugPrint('📦 Event data: $data');
    });
  }

  // Send message
  void sendMessage({
    required String chatId,
    required String content,
    List<String>? attachments,
    String? replyToId,
  }) {
    if (!_isConnected || _socket == null) {
      debugPrint('Socket not connected, cannot send message');
      return;
    }

    _socket!.emit('sendMessage', {
      'chatId': chatId,
      'content': content,
      'attachments': attachments,
      'replyTo': replyToId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Edit message
  void editMessage({required String messageId, required String newContent}) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('editMessage', {
      'messageId': messageId,
      'content': newContent,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Delete message
  void deleteMessage(String messageId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('deleteMessage', {'messageId': messageId});
  }

  // Join chat room
  void joinChat(String chatId) {
    if (!_isConnected || _socket == null) return;

    debugPrint('🔗 Socket: Joining chat room: $chatId');
    _socket!.emit('joinChat', chatId); // Backend expects just the chatId string
  }

  // Join multiple chats (when user connects)
  void joinMultipleChats(List<String> chatIds) {
    if (!_isConnected || _socket == null) return;

    for (final chatId in chatIds) {
      joinChat(chatId);
    }
    debugPrint('✅ Socket: Joined ${chatIds.length} chat rooms');
  }

  // Join user groups (including default group)
  void joinUserGroups(String userId) {
    if (!_isConnected || _socket == null) {
      debugPrint('❌ Socket not connected, cannot join user groups');
      return;
    }

    debugPrint('🔗 Socket: Requesting to join user groups for user: $userId');
    _socket!.emit('join_user_groups', userId);
  }

  // Leave chat room
  void leaveChat(String chatId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('leaveChat', {'chatId': chatId});
  }

  // Send typing indicator
  void sendTyping(String chatId, bool isTyping) {
    if (!_isConnected || _socket == null) return;

    if (isTyping) {
      _socket!.emit('typing', {'chatId': chatId});
    } else {
      _socket!.emit('stopTyping', {'chatId': chatId});
    }
  }

  // Mark message as read
  void markMessageAsRead(String messageId, {String? chatId}) {
    if (!_isConnected || _socket == null) {
      debugPrint('❌ Socket not connected, cannot mark message as read');
      return;
    }

    debugPrint(
      '📡 Socket: Emitting messageRead event for message: $messageId, chatId: $chatId',
    );
    _socket!.emit('messageRead', {
      'messageId': messageId,
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Mark message as delivered
  void markMessageAsDelivered(String messageId, {String? chatId}) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('messageDelivered', {
      'messageId': messageId,
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Retry failed message
  void retryMessage(String messageId) {
    if (!_isConnected || _socket == null) return;

    debugPrint('🔄 Socket: Retrying message: $messageId');
    _socket!.emit('messageRetry', {
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Request message status
  void requestMessageStatus(String messageId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('requestMessageStatus', {'messageId': messageId});
  }

  // Mark all messages in chat as read
  void markChatAsRead(String chatId) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('markChatRead', {'chatId': chatId});
  }

  // Update user status
  void updateUserStatus(dynamic statusData) {
    if (!_isConnected || _socket == null) return;

    debugPrint('📡 Socket: Updating user status: $statusData');

    if (statusData is String) {
      // Legacy support for simple status strings
      _socket!.emit('updateStatus', {'status': statusData});
    } else if (statusData is Map) {
      // New presence event format
      _socket!.emit('status:update', statusData);
    }
  }

  // Send presence events
  void sendPresenceEvent(String event, Map<String, dynamic> data) {
    if (!_isConnected || _socket == null) return;

    debugPrint('📡 Socket: Sending presence event: $event with data: $data');
    _socket!.emit(event, data);
  }

  // Upload file with progress
  void uploadFile({
    required String chatId,
    required String filePath,
    required String fileName,
    String? caption,
    Function(double)? onProgress,
  }) {
    if (!_isConnected || _socket == null) return;

    // This would typically be handled by a separate file upload service
    // but we emit the event to notify about file upload intent
    _socket!.emit('uploadFile', {
      'chatId': chatId,
      'fileName': fileName,
      'caption': caption,
    });
  }

  // Reconnect manually
  Future<void> reconnect() async {
    if (_socket != null) {
      _socket!.connect();
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _currentUserId = null;
    _connectionStreamController.add(false);
  }

  // Dispose all resources
  void dispose() {
    disconnect();
    _messageStreamController.close();
    _typingStreamController.close();
    _userStatusStreamController.close();
    _chatUpdateStreamController.close();
    _connectionStreamController.close();

    // Close message status stream controllers
    _messageStatusUpdateStreamController.close();
    _messageDeliveredStreamController.close();
    _messageReadStreamController.close();
    _messageSentStreamController.close();
    _messageFailedStreamController.close();
  }

  // Get connection status
  bool getConnectionStatus() {
    return _isConnected && _socket != null;
  }

  // Get socket instance
  IO.Socket? get socket => _socket;

  // Emit custom event
  void emit(String event, dynamic data) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit(event, data);
  }

  // Listen to custom event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // Remove custom event listener
  void off(String event) {
    _socket?.off(event);
  }
}
