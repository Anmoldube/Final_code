import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/enhanced_auth_service.dart';
import '../../../../core/config/api_config.dart';

class ChatApiService {
  late final Dio _dio;

  ChatApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
        // Enable cookie support for authentication
        extra: {
          'withCredentials': true,
        },
      ),
    );

    // Add enhanced auth interceptor
    _dio.interceptors.add(EnhancedAuthInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  // Get all chats for current user
  Future<Response> getAllChats() async {
    return await _dio.get('/api/chat');
  }

  // Create or get existing direct chat
  Future<Response> createOrGetDirectChat(String userId) async {
    return await _dio.post('/api/chat/c/$userId');
  }

  // Create group chat
  Future<Response> createGroupChat({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    return await _dio.post(
      '/api/chat/group',
      data: {
        'name': name,
        'description': description,
        'participants': participantIds,
      },
    );
  }

  // Get group chat details
  Future<Response> getGroupChatDetails(String chatId) async {
    return await _dio.get('/api/chat/group/$chatId');
  }

  // Add user to group chat
  Future<Response> addUserToGroup(String chatId, String userId) async {
    return await _dio.put('/api/chat/group/$chatId', data: {'userId': userId});
  }

  // Delete chat
  Future<Response> deleteChat(String chatId) async {
    return await _dio.delete('/api/chat/$chatId');
  }

  // Search chats
  Future<Response> searchChats(String query) async {
    return await _dio.get('/api/chat/search', queryParameters: {'q': query});
  }

  // Get available users for chat creation
  Future<Response> getAvailableUsers({String? query}) async {
    final queryParams = <String, dynamic>{};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }

    return await _dio.get('/api/chat/users', queryParameters: queryParams);
  }

  // Mark chat as read
  Future<Response> markChatAsRead(String chatId) async {
    return await _dio.post('/api/messages/$chatId/read');
  }

  // Update group chat details
  Future<Response> updateGroupChat({
    required String chatId,
    String? name,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;

    return await _dio.put('/api/chat/group/$chatId', data: data);
  }

  // Leave group chat
  Future<Response> leaveGroupChat(String chatId) async {
    return await _dio.delete('/api/chat/group/$chatId/leave');
  }

  // Remove user from group
  Future<Response> removeUserFromGroup(String chatId, String userId) async {
    return await _dio.delete('/api/chat/group/$chatId/users/$userId');
  }

  // Get chat members
  Future<Response> getChatMembers(String chatId) async {
    return await _dio.get('/api/chat/$chatId/members');
  }

  // Mute/Unmute chat
  Future<Response> toggleChatMute(String chatId, bool mute) async {
    return await _dio.put('/api/chat/$chatId/mute', data: {'mute': mute});
  }

  // Pin/Unpin chat
  Future<Response> toggleChatPin(String chatId, bool pin) async {
    return await _dio.put('/api/chat/$chatId/pin', data: {'pin': pin});
  }
}
