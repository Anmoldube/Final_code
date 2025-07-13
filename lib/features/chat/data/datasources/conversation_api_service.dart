import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/config/api_config.dart';

class ConversationApiService {
  late final Dio _dio;

  ConversationApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
        extra: {'withCredentials': true},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_ConversationInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  /// Get all conversations for the current user, sorted by last message timestamp
  Future<List<ConversationModel>> getConversations() async {
    try {
      print('🔄 Fetching conversations...');
      final response = await _dio.get('/api/chat/conversations');

      print('📨 Conversations response: ${response.data}');

      if (response.data != null && response.data['data'] is List) {
        final conversations = (response.data['data'] as List)
            .map((json) => ConversationModel.fromJson(json))
            .toList();

        print('✅ Parsed ${conversations.length} conversations');
        return conversations;
      } else {
        print('❌ Unexpected response format: ${response.data}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching conversations: $e');
      return [];
    }
  }

  /// Mark a conversation as read
  Future<void> markConversationAsRead(String chatId) async {
    try {
      print('🔄 Marking conversation as read: $chatId');
      await _dio.post('/api/chat/$chatId/read');
      print('✅ Conversation marked as read');
    } catch (e) {
      print('❌ Error marking conversation as read: $e');
      rethrow;
    }
  }
}

class _ConversationInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authentication token if available
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ Conversation API Error: ${err.message}');
    handler.next(err);
  }
}
