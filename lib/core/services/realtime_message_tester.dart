import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../services/chat_debug_service.dart';
import '../models/chat_model.dart';

class RealtimeMessageTester {
  static final Dio _dio = Dio();

  /// Comprehensive test for real-time messaging
  static Future<void> testCompleteMessageFlow() async {
    debugPrint('🧪 ===== STARTING COMPLETE MESSAGE FLOW TEST =====');

    try {
      // Step 1: Check authentication
      await _testAuthentication();

      // Step 2: Check socket connection
      await _testSocketConnection();

      // Step 3: Get user's chats
      final userChats = await _getUserChats();

      if (userChats.isEmpty) {
        debugPrint('❌ No chats found for user');
        return;
      }

      // Step 4: Test message sending and receiving
      final testChatId = userChats.first['_id'];
      await _testMessageSendingAndReceiving(testChatId);

      debugPrint('🎉 ===== COMPLETE MESSAGE FLOW TEST COMPLETED =====');
    } catch (e) {
      debugPrint('❌ Message flow test failed: $e');
    }
  }

  static Future<void> _testAuthentication() async {
    debugPrint('🔐 Testing authentication...');

    final token = await StorageService.getAccessToken();
    if (token == null) {
      throw Exception('No access token found');
    }

    _dio.options.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/api/chat');
      debugPrint('✅ Authentication test passed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Authentication test failed: $e');
      rethrow;
    }
  }

  static Future<void> _testSocketConnection() async {
    debugPrint('🔌 Testing socket connection...');

    final isConnected = SocketService.instance.isConnected;
    debugPrint('Socket connected: $isConnected');

    if (!isConnected) {
      final userId = StorageService.getUserId();
      if (userId != null) {
        debugPrint('🔄 Attempting to connect socket...');
        await SocketService.instance.connect(userId);

        // Wait for connection
        await Future.delayed(Duration(seconds: 2));

        if (SocketService.instance.isConnected) {
          debugPrint('✅ Socket connection test passed');
        } else {
          throw Exception('Socket connection failed');
        }
      } else {
        throw Exception('No user ID found for socket connection');
      }
    } else {
      debugPrint('✅ Socket already connected');
    }
  }

  static Future<List<dynamic>> _getUserChats() async {
    debugPrint('📋 Getting user chats...');

    try {
      final response = await _dio.get('${ApiConfig.baseUrl}/api/chat');
      final chats = response.data['data'] as List<dynamic>;

      debugPrint('✅ Found ${chats.length} chats');
      for (var chat in chats) {
        debugPrint('  - ${chat['_id']}: ${chat['name'] ?? 'Direct Chat'}');
      }

      return chats;
    } catch (e) {
      debugPrint('❌ Failed to get user chats: $e');
      rethrow;
    }
  }

  static Future<void> _testMessageSendingAndReceiving(String chatId) async {
    debugPrint('💬 Testing message sending and receiving for chat: $chatId');

    // Listen for socket messages
    bool messageReceived = false;
    final subscription = SocketService.instance.messageStream.listen((message) {
      debugPrint('🔄 Received socket message: ${message.content}');
      if (message.chatId == chatId) {
        messageReceived = true;
        debugPrint('✅ Message received via socket for correct chat');
      }
    });

    try {
      // Send a test message
      final testMessage =
          'Test message - ${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('📤 Sending test message: $testMessage');

      final response = await _dio.post(
        '${ApiConfig.baseUrl}/api/messages/$chatId',
        data: {'content': testMessage},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Message sent successfully');

        // Wait for socket message
        await Future.delayed(Duration(seconds: 3));

        if (messageReceived) {
          debugPrint('🎉 Real-time message receiving works!');
        } else {
          debugPrint('⚠️ Message sent but not received via socket');
        }
      } else {
        debugPrint('❌ Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Message sending test failed: $e');
    } finally {
      subscription.cancel();
    }
  }

  /// Quick socket status check
  static void quickSocketCheck() {
    debugPrint('🔍 ===== QUICK SOCKET STATUS CHECK =====');
    debugPrint('Socket connected: ${SocketService.instance.isConnected}');
    debugPrint('Current user ID: ${SocketService.instance.currentUserId}');
    debugPrint(
      'Socket ID: ${SocketService.instance.socketId ?? 'Not connected'}',
    );

    final userId = StorageService.getUserId();
    debugPrint('Stored user ID: $userId');

    if (userId != null && !SocketService.instance.isConnected) {
      debugPrint('⚠️ User logged in but socket not connected');
      debugPrint('💡 Suggestion: Call SocketService.instance.connect(userId)');
    }

    debugPrint('=====================================');
  }

  /// Debug specific chat participants
  static Future<void> debugChatParticipants(String chatId) async {
    debugPrint('🔍 Debugging chat participants for: $chatId');

    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ No access token found');
        return;
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      // Get chat details
      final chatResponse = await _dio.get('${ApiConfig.baseUrl}/api/chat');
      final chats = chatResponse.data['data'] as List<dynamic>;

      final targetChatData = chats.firstWhere(
        (chat) => chat['_id'] == chatId,
        orElse: () => null,
      );

      if (targetChatData != null) {
        debugPrint('✅ Found chat data');
        ChatDebugService.debugRawChatData(targetChatData);

        final chatModel = ChatModel.fromJson(targetChatData);
        ChatDebugService.debugChatParticipants(chatModel);
      } else {
        debugPrint('❌ Chat not found');
      }
    } catch (e) {
      debugPrint('❌ Chat debug error: $e');
    }
  }

  /// Test specific chat ownership
  static Future<void> testChatOwnership(String chatId) async {
    debugPrint('🔍 Testing chat ownership for: $chatId');

    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ No access token found');
        return;
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get(
        '${ApiConfig.baseUrl}/api/messages/$chatId',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('✅ Chat ownership verified - user can access this chat');
      } else if (response.statusCode == 401) {
        debugPrint('❌ Chat ownership failed - user cannot access this chat');
        debugPrint(
          '💡 Try using a different chat ID or check user permissions',
        );
      }
    } catch (e) {
      debugPrint('❌ Chat ownership test error: $e');
    }
  }
}
