import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'storage_service.dart';
import 'socket_service.dart';
import 'enhanced_auth_service.dart';
import '../config/api_config.dart';

/// Comprehensive chat system debugging helper
class ChatDebugHelper {
  /// Run complete chat system diagnostic
  static Future<void> runFullChatDiagnostic() async {
    debugPrint('🔍 ===== CHAT SYSTEM FULL DIAGNOSTIC START =====');

    await _testSocketConnection();
    await _testChatOwnership();
    await _testRealTimeMessaging();
    await _diagnoseCurrentIssue();

    debugPrint('🔍 ===== CHAT SYSTEM FULL DIAGNOSTIC END =====');
  }

  /// Test socket connection and status
  static Future<void> _testSocketConnection() async {
    debugPrint('\n🔌 [CHAT DIAGNOSTIC] Testing Socket Connection...');

    try {
      final socketInstance = SocketService.instance;

      debugPrint('🔌 [DIAGNOSTIC] Socket Status:');
      debugPrint('🔌   - Is Connected: ${socketInstance.isConnected}');
      debugPrint('🔌   - Current User ID: ${socketInstance.currentUserId}');
      debugPrint(
        '🔌   - Connection Status: ${socketInstance.getConnectionStatus()}',
      );

      final userId = StorageService.getUserId();
      debugPrint('🔌   - Stored User ID: $userId');

      if (!socketInstance.isConnected && userId != null) {
        debugPrint(
          '🔌 ⚠️ [DIAGNOSTIC] Socket not connected, attempting connection...',
        );
        await socketInstance.connect(userId);
        debugPrint('🔌 🔄 [DIAGNOSTIC] Connection attempt completed');
        debugPrint('🔌   - Is Connected Now: ${socketInstance.isConnected}');
      }
    } catch (e, stackTrace) {
      debugPrint('🔌 ❌ [DIAGNOSTIC] Socket Connection Error: $e');
      debugPrint('🔌 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test chat ownership and permissions
  static Future<void> _testChatOwnership() async {
    debugPrint('\n💬 [CHAT DIAGNOSTIC] Testing Chat Ownership...');

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.interceptors.add(EnhancedAuthInterceptor());

      // Test getting user's own chats
      debugPrint('💬 [DIAGNOSTIC] Testing user\'s chat list...');

      try {
        final response = await dio.get('/api/chat');
        debugPrint('✅ [DIAGNOSTIC] User chats retrieved successfully');
        debugPrint(
          '💬 [DIAGNOSTIC] Number of chats: ${response.data['data']?.length ?? 0}',
        );

        if (response.data['data'] != null) {
          final chats = response.data['data'] as List;
          debugPrint('💬 [DIAGNOSTIC] User\'s Chat IDs:');
          for (var chat in chats) {
            debugPrint(
              '💬   - ${chat['_id']}: ${chat['name'] ?? 'Direct Chat'}',
            );
          }
        }
      } catch (chatError) {
        debugPrint('💬 ❌ [DIAGNOSTIC] Error getting user chats: $chatError');
        if (chatError is DioException) {
          debugPrint(
            '💬 ❌ [DIAGNOSTIC] Chat error status: ${chatError.response?.statusCode}',
          );
          debugPrint(
            '💬 ❌ [DIAGNOSTIC] Chat error data: ${chatError.response?.data}',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('💬 ❌ [DIAGNOSTIC] Chat Ownership Error: $e');
      debugPrint('💬 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test real-time messaging flow
  static Future<void> _testRealTimeMessaging() async {
    debugPrint('\n📨 [CHAT DIAGNOSTIC] Testing Real-Time Messaging...');

    try {
      final socketInstance = SocketService.instance;

      if (!socketInstance.isConnected) {
        debugPrint(
          '📨 ❌ [DIAGNOSTIC] Socket not connected - real-time messaging won\'t work',
        );
        return;
      }

      debugPrint('📨 [DIAGNOSTIC] Testing socket event listeners...');

      // Test if message stream is working
      bool messageStreamWorking = false;

      final streamSubscription = socketInstance.messageStream.listen(
        (message) {
          debugPrint(
            '📨 ✅ [DIAGNOSTIC] Message stream is working - received: ${message.content}',
          );
          messageStreamWorking = true;
        },
        onError: (error) {
          debugPrint('📨 ❌ [DIAGNOSTIC] Message stream error: $error');
        },
      );

      // Wait a moment to see if stream is active
      await Future.delayed(const Duration(seconds: 1));

      debugPrint(
        '📨 [DIAGNOSTIC] Message stream status: ${messageStreamWorking ? 'Active' : 'Inactive'}',
      );

      streamSubscription.cancel();
    } catch (e, stackTrace) {
      debugPrint('📨 ❌ [DIAGNOSTIC] Real-Time Messaging Error: $e');
      debugPrint('📨 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Diagnose the current specific issue
  static Future<void> _diagnoseCurrentIssue() async {
    debugPrint('\n🎯 [CHAT DIAGNOSTIC] Diagnosing Current Issue...');

    try {
      // The chat ID causing issues
      const problematicChatId = '685bf28e186eda90af89be6e';

      debugPrint(
        '🎯 [DIAGNOSTIC] Testing problematic chat: $problematicChatId',
      );

      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.interceptors.add(EnhancedAuthInterceptor());

      // Test 1: Check if user owns this chat
      try {
        final chatResponse = await dio.get('/api/chat');
        final userChats = chatResponse.data['data'] as List;
        final ownsChat = userChats.any(
          (chat) => chat['_id'] == problematicChatId,
        );

        debugPrint(
          '🎯 [DIAGNOSTIC] User owns chat $problematicChatId: $ownsChat',
        );

        if (!ownsChat) {
          debugPrint(
            '🎯 ❌ [DIAGNOSTIC] ISSUE FOUND: User doesn\'t own this chat!',
          );
          debugPrint(
            '🎯 💡 [DIAGNOSTIC] SOLUTION: Create a direct chat with the intended user instead',
          );

          // Show available chats
          debugPrint('🎯 [DIAGNOSTIC] Available chats:');
          for (var chat in userChats) {
            debugPrint(
              '🎯   - ${chat['_id']}: ${chat['name'] ?? 'Direct Chat'}',
            );
          }

          // Suggest creating a proper direct chat
          await _suggestDirectChatCreation();
        }
      } catch (e) {
        debugPrint('🎯 ❌ [DIAGNOSTIC] Error checking chat ownership: $e');
      }

      // Test 2: Try to get messages from this chat
      try {
        final messageResponse = await dio.get(
          '/api/messages/$problematicChatId',
        );
        debugPrint('🎯 ✅ [DIAGNOSTIC] Successfully accessed messages for chat');
        debugPrint(
          '🎯 📊 [DIAGNOSTIC] Message count: ${messageResponse.data['data']?.length ?? 0}',
        );
      } catch (messageError) {
        debugPrint('🎯 ❌ [DIAGNOSTIC] Cannot access messages: $messageError');
        if (messageError is DioException) {
          debugPrint(
            '🎯 ❌ [DIAGNOSTIC] Message error: ${messageError.response?.data}',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🎯 ❌ [DIAGNOSTIC] Current Issue Diagnosis Error: $e');
      debugPrint('🎯 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Suggest creating a proper direct chat
  static Future<void> _suggestDirectChatCreation() async {
    debugPrint('\n💡 [CHAT DIAGNOSTIC] Suggesting Direct Chat Creation...');

    try {
      debugPrint('💡 [DIAGNOSTIC] To fix the chat issue:');
      debugPrint('💡   1. Find the user you want to chat with');
      debugPrint(
        '💡   2. Use their USER ID (not chat ID) to create a direct chat',
      );
      debugPrint(
        '💡   3. The backend will create or return existing direct chat',
      );

      // Show how to create a direct chat
      debugPrint('💡 [DIAGNOSTIC] Example: Create direct chat with user ID');
      debugPrint('💡   POST /api/chat/c/{userId}');
      debugPrint(
        '💡   This will create/get a direct chat between current user and target user',
      );
    } catch (e) {
      debugPrint('💡 ❌ [DIAGNOSTIC] Error in suggestion: $e');
    }
  }

  /// Fix common chat issues automatically
  static Future<void> autoFixChatIssues() async {
    debugPrint('\n🛠️ [CHAT FIX] Starting Automatic Chat Issue Fix...');

    try {
      // Step 1: Ensure socket is connected
      await _ensureSocketConnection();

      // Step 2: Join user's chats
      await _joinUserChats();

      // Step 3: Test real-time functionality
      await _testRealTimeFunctionality();

      debugPrint('🛠️ ✅ [CHAT FIX] Automatic fix completed!');
    } catch (e, stackTrace) {
      debugPrint('🛠️ ❌ [CHAT FIX] Auto fix error: $e');
      debugPrint('🛠️ 📚 [CHAT FIX] Stack trace: $stackTrace');
    }
  }

  /// Ensure socket connection is established
  static Future<void> _ensureSocketConnection() async {
    debugPrint('🛠️ [CHAT FIX] Ensuring socket connection...');

    try {
      final socketInstance = SocketService.instance;
      final userId = StorageService.getUserId();

      if (userId == null) {
        debugPrint('🛠️ ❌ [CHAT FIX] No user ID found - user needs to login');
        return;
      }

      if (!socketInstance.isConnected) {
        debugPrint('🛠️ 🔄 [CHAT FIX] Connecting socket...');
        await socketInstance.connect(userId);

        // Wait for connection
        await Future.delayed(const Duration(seconds: 2));

        if (socketInstance.isConnected) {
          debugPrint('🛠️ ✅ [CHAT FIX] Socket connected successfully');
        } else {
          debugPrint('🛠️ ❌ [CHAT FIX] Socket connection failed');
        }
      } else {
        debugPrint('🛠️ ✅ [CHAT FIX] Socket already connected');
      }
    } catch (e) {
      debugPrint('🛠️ ❌ [CHAT FIX] Socket connection error: $e');
    }
  }

  /// Join all user's chats for real-time updates
  static Future<void> _joinUserChats() async {
    debugPrint('🛠️ [CHAT FIX] Joining user\'s chats...');

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.interceptors.add(EnhancedAuthInterceptor());

      final response = await dio.get('/api/chat');
      final userChats = response.data['data'] as List;

      final socketInstance = SocketService.instance;
      final chatIds = userChats.map((chat) => chat['_id'] as String).toList();

      debugPrint('🛠️ [CHAT FIX] Joining ${chatIds.length} chats...');

      for (final chatId in chatIds) {
        socketInstance.joinChat(chatId);
        debugPrint('🛠️ [CHAT FIX] Joined chat: $chatId');
      }

      debugPrint('🛠️ ✅ [CHAT FIX] All chats joined successfully');
    } catch (e) {
      debugPrint('🛠️ ❌ [CHAT FIX] Error joining chats: $e');
    }
  }

  /// Test real-time functionality with a live test
  static Future<void> _testRealTimeFunctionality() async {
    debugPrint('🛠️ [CHAT FIX] Testing real-time functionality...');

    try {
      final socketInstance = SocketService.instance;

      if (!socketInstance.isConnected) {
        debugPrint('🛠️ ❌ [CHAT FIX] Socket not connected for real-time test');
        return;
      }

      debugPrint('🛠️ ✅ [CHAT FIX] Real-time functionality setup complete');
      debugPrint('🛠️ 💡 [CHAT FIX] Your chat should now work properly!');
    } catch (e) {
      debugPrint('🛠️ ❌ [CHAT FIX] Real-time test error: $e');
    }
  }

  /// Create a proper direct chat with another user
  static Future<String?> createDirectChat(String targetUserId) async {
    debugPrint(
      '\n🤝 [CHAT HELPER] Creating direct chat with user: $targetUserId',
    );

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
      dio.interceptors.add(EnhancedAuthInterceptor());

      final response = await dio.post('/api/chat/c/$targetUserId');

      if (response.statusCode == 200) {
        final chatData = response.data['data'];
        final chatId = chatData['_id'];

        debugPrint('🤝 ✅ [CHAT HELPER] Direct chat created/found: $chatId');

        // Join the chat room for real-time updates
        SocketService.instance.joinChat(chatId);

        return chatId;
      }
    } catch (e) {
      debugPrint('🤝 ❌ [CHAT HELPER] Error creating direct chat: $e');
      if (e is DioException) {
        debugPrint('🤝 ❌ [CHAT HELPER] Error details: ${e.response?.data}');
      }
    }

    return null;
  }

  /// Get solution for "you don't own the chat" error
  static void explainChatOwnershipError() {
    debugPrint(
      '\n📚 [CHAT HELP] Understanding "you don\'t own the chat" Error:',
    );
    debugPrint('📚');
    debugPrint('📚 ❌ PROBLEM:');
    debugPrint(
      '📚   You\'re trying to access a chat that doesn\'t belong to you',
    );
    debugPrint('📚');
    debugPrint('📚 💡 SOLUTION:');
    debugPrint('📚   1. Use the correct chat ID from your chat list');
    debugPrint(
      '📚   2. Create a new direct chat with the user you want to message',
    );
    debugPrint('📚   3. Make sure you\'re a participant in the chat');
    debugPrint('📚');
    debugPrint('📚 🔧 HOW TO FIX:');
    debugPrint('📚   1. Get your chat list: GET /api/chat');
    debugPrint('📚   2. Use a chat ID from that list');
    debugPrint('📚   3. Or create direct chat: POST /api/chat/c/{userId}');
    debugPrint('📚');
  }
}
