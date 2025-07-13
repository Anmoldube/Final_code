import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/enhanced_auth_service.dart';
import '../../../../core/config/api_config.dart';

class MessageApiService {
  late final Dio _dio;

  MessageApiService() {
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

  // Get messages for a chat
  Future<Response> getMessages(String chatId, {DateTime? before}) async {
    final queryParams = <String, dynamic>{};
    if (before != null) {
      queryParams['before'] = before.toIso8601String();
    }

    return await _dio.get(
      '/api/messages/$chatId',
      queryParameters: queryParams,
    );
  }

  // Send a text message
  Future<Response> sendMessage({
    required String chatId,
    required String content,
    List<String>? attachments,
    String? replyToId,
  }) async {
    final data = <String, dynamic>{'content': content};

    if (replyToId != null) {
      data['replyTo'] = replyToId;
    }

    if (attachments != null && attachments.isNotEmpty) {
      data['attachments'] = attachments;
    }



    return await _dio.post('/api/messages/$chatId', data: data);
  }

  // Send file message
  Future<Response> sendFileMessage({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    final formData = FormData();

    formData.files.add(
      MapEntry('attachments', await MultipartFile.fromFile(filePath)),
    );

    if (caption != null && caption.isNotEmpty) {
      formData.fields.add(MapEntry('content', caption));
    }

    return await _dio.post(
      '/api/messages/$chatId',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  // Send multiple files
  Future<Response> sendMultipleFiles({
    required String chatId,
    required List<String> filePaths,
    String? caption,
  }) async {
    final formData = FormData();

    for (final filePath in filePaths) {
      formData.files.add(
        MapEntry('attachments', await MultipartFile.fromFile(filePath)),
      );
    }

    if (caption != null && caption.isNotEmpty) {
      formData.fields.add(MapEntry('content', caption));
    }

    return await _dio.post(
      '/api/messages/$chatId',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  // Delete a message
  Future<Response> deleteMessage(String messageId) async {
    return await _dio.delete('/api/messages/$messageId');
  }

  // Edit a message
  Future<Response> editMessage(String messageId, String newContent) async {
    return await _dio.put(
      '/api/messages/$messageId',
      data: {'content': newContent},
    );
  }

  // Mark message as read
  Future<Response> markMessageAsRead(String messageId) async {
    return await _dio.post('/api/messages/$messageId/read');
  }

  // Mark all messages in chat as read
  Future<Response> markAllMessagesAsRead(String chatId) async {
    return await _dio.post('/api/messages/$chatId/read');
  }

  // Get unread messages count for a chat
  Future<Response> getUnreadMessagesCount(String chatId) async {
    return await _dio.get('/api/messages/$chatId/unread');
  }

  // Search messages in a chat
  Future<Response> searchMessages(String chatId, String query) async {
    return await _dio.get(
      '/messages/$chatId/search',
      queryParameters: {'q': query},
    );
  }

  // Clear chat (delete all messages)
  Future<Response> clearChat(String chatId) async {
    return await _dio.delete('/messages/$chatId/clear');
  }

  // Get all unread messages across all chats
  Future<Response> getAllUnreadMessages() async {
    return await _dio.get('/api/messages/unread');
  }

  // Download file attachment
  Future<Response> downloadFile(String fileUrl, String savePath) async {
    return await _dio.download(
      fileUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      },
    );
  }

  // Upload file and get URL
  Future<Response> uploadFile(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    return await _dio.post('/upload', data: formData);
  }

  // React to a message
  Future<Response> reactToMessage(String messageId, String reaction) async {
    return await _dio.post(
      '/messages/$messageId/react',
      data: {'reaction': reaction},
    );
  }

  // Remove reaction from message
  Future<Response> removeReaction(String messageId, String reaction) async {
    return await _dio.delete(
      '/messages/$messageId/react',
      data: {'reaction': reaction},
    );
  }

  // Forward message
  Future<Response> forwardMessage({
    required String messageId,
    required String toChatId,
  }) async {
    return await _dio.post(
      '/messages/$messageId/forward',
      data: {'toChatId': toChatId},
    );
  }

  // Get message reactions
  Future<Response> getMessageReactions(String messageId) async {
    return await _dio.get('/messages/$messageId/reactions');
  }
}
