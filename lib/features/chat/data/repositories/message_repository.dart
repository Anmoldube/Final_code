import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/message_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/offline_service.dart';
import '../datasources/message_api_service.dart';

class MessageRepository {
  final MessageApiService _apiService;

  MessageRepository({MessageApiService? apiService})
    : _apiService = apiService ?? MessageApiService();

  // Get messages for a chat
  Future<List<MessageModel>> getMessages(
    String chatId, {
    DateTime? before,
  }) async {
    try {
      // Check if we're online
      final isOnline = OfflineService().isOnline;

      if (!isOnline) {
        debugPrint(
          '📱 Repository: Device is offline, loading messages from local storage',
        );
        return _getMessagesFromLocalStorage(chatId);
      }

      final response = await _apiService.getMessages(chatId, before: before);

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle both possible response formats
        if (data['success'] == true ||
            data['statusCode'] == '10000' ||
            data['statusCode'] == 10000) {
          List<dynamic> messagesJson;

          // Try different response structures
          if (data['messages'] != null) {
            messagesJson = data['messages'] as List<dynamic>;
          } else if (data['data'] != null && data['data'] is List) {
            messagesJson = data['data'] as List<dynamic>;
          } else {
            messagesJson = [];
          }

          // Mark messages as synced
          for (final messageJson in messagesJson) {
            messageJson['isSynced'] = true;
            messageJson['lastSyncedAt'] = DateTime.now().toIso8601String();
            messageJson['isLocalOnly'] = false;
          }

          final messages = messagesJson
              .map((messageJson) => MessageModel.fromJson(messageJson))
              .toList();

          // Save to local storage
          await StorageService.saveMessages(
            chatId,
            messages.map((msg) => msg.toJson()).toList(),
          );

          return messages;
        } else {
          throw Exception(data['message'] ?? 'Failed to load messages');
        }
      } else {
        throw Exception(
          'Failed to load messages with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Try to load from local storage if network fails
      final localMessages = StorageService.getMessages(chatId);
      if (localMessages != null) {
        return localMessages
            .map((messageData) => MessageModel.fromJson(messageData))
            .toList();
      }
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Get messages error: $e');

      // Try to load from local storage
      final localMessages = StorageService.getMessages(chatId);
      if (localMessages != null) {
        return localMessages
            .map((messageData) => MessageModel.fromJson(messageData))
            .toList();
      }

      throw Exception('Failed to load messages: $e');
    }
  }

  // Send a new message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    List<String>? attachments,
    String? replyToId,
  }) async {
    try {
      // Check if we're online
      final isOnline = OfflineService().isOnline;

      if (!isOnline) {
        debugPrint('📱 Repository: Device is offline, saving message locally');
        return _saveOfflineMessage(
          chatId: chatId,
          content: content,
          attachments: attachments,
          replyToId: replyToId,
        );
      }

      final response = await _apiService.sendMessage(
        chatId: chatId,
        content: content,
        attachments: attachments,
        replyToId: replyToId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Handle both possible response formats
        if (data['success'] == true ||
            data['statusCode'] == '10000' ||
            data['statusCode'] == 10000) {
          dynamic messageJson;

          // Try different response structures
          if (data['message'] != null && data['message'] is Map) {
            messageJson = data['message'];
          } else if (data['data'] != null) {
            messageJson = data['data'];
          } else {
            messageJson = data;
          }

          // Mark as synced
          messageJson['isSynced'] = true;
          messageJson['lastSyncedAt'] = DateTime.now().toIso8601String();
          messageJson['isLocalOnly'] = false;

          final message = MessageModel.fromJson(messageJson);

          // Add to local storage
          await StorageService.addMessage(chatId, message.toJson());

          return message;
        } else {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception(
          'Failed to send message with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // If we have a network error, try to save offline
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('📱 Repository: Network error, saving message locally');
        return _saveOfflineMessage(
          chatId: chatId,
          content: content,
          attachments: attachments,
          replyToId: replyToId,
        );
      }
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Send message error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Send file message
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    try {
      final response = await _apiService.sendFileMessage(
        chatId: chatId,
        filePath: filePath,
        caption: caption,
      );

      if (response.statusCode == 201) {
        final data = response.data;

        if (data['success'] == true) {
          final messageJson = data['message'];
          final message = MessageModel.fromJson(messageJson);

          // Add to local storage
          await StorageService.addMessage(chatId, message.toJson());

          return message;
        } else {
          throw Exception(data['message'] ?? 'Failed to send file');
        }
      } else {
        throw Exception(
          'Failed to send file with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Send file message error: $e');
      throw Exception('Failed to send file: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final response = await _apiService.deleteMessage(messageId);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to delete message with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Delete message error: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  // Edit a message
  Future<MessageModel> editMessage(String messageId, String newContent) async {
    try {
      final response = await _apiService.editMessage(messageId, newContent);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final messageJson = data['message'];
          return MessageModel.fromJson(messageJson);
        } else {
          throw Exception(data['message'] ?? 'Failed to edit message');
        }
      } else {
        throw Exception(
          'Failed to edit message with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Edit message error: $e');
      throw Exception('Failed to edit message: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _apiService.markMessageAsRead(messageId);
    } on DioException catch (e) {
      debugPrint('Mark message as read error: $e');
      // Don't throw error for this operation
    } catch (e) {
      debugPrint('Mark message as read error: $e');
    }
  }

  // Mark all messages in chat as read
  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      await _apiService.markAllMessagesAsRead(chatId);
    } on DioException catch (e) {
      debugPrint('Mark all messages as read error: $e');
      // Don't throw error for this operation
    } catch (e) {
      debugPrint('Mark all messages as read error: $e');
    }
  }

  // Get unread messages count
  Future<int> getUnreadMessagesCount(String chatId) async {
    try {
      final response = await _apiService.getUnreadMessagesCount(chatId);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          return data['count'] ?? 0;
        }
      }
      return 0;
    } on DioException catch (e) {
      debugPrint('Get unread messages count error: $e');
      return 0;
    } catch (e) {
      debugPrint('Get unread messages count error: $e');
      return 0;
    }
  }

  // Search messages in chat
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      final response = await _apiService.searchMessages(chatId, query);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final messagesJson = data['messages'] as List<dynamic>;
          return messagesJson
              .map((messageJson) => MessageModel.fromJson(messageJson))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to search messages');
        }
      } else {
        throw Exception(
          'Failed to search messages with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('Search messages error: $e');
      return [];
    } catch (e) {
      debugPrint('Search messages error: $e');
      return [];
    }
  }

  // Clear chat (delete all messages)
  Future<void> clearChat(String chatId) async {
    try {
      final response = await _apiService.clearChat(chatId);

      if (response.statusCode == 200) {
        // Clear from local storage
        await StorageService.clearMessages(chatId);
      } else {
        throw Exception(
          'Failed to clear chat with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Clear chat error: $e');
      throw Exception('Failed to clear chat: $e');
    }
  }

  // Get all unread messages
  Future<List<MessageModel>> getAllUnreadMessages() async {
    try {
      final response = await _apiService.getAllUnreadMessages();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final messagesJson = data['messages'] as List<dynamic>;
          return messagesJson
              .map((messageJson) => MessageModel.fromJson(messageJson))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get unread messages');
        }
      } else {
        throw Exception(
          'Failed to get unread messages with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Get all unread messages error: $e');
      return [];
    }
  }

  Exception _handleDioException(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Response timeout. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          message = 'Access denied.';
        } else if (statusCode == 404) {
          message = 'Message not found.';
        } else if (statusCode == 422) {
          if (data is Map<String, dynamic> && data['message'] != null) {
            message = data['message'];
          } else {
            message = 'Invalid input.';
          }
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          if (data is Map<String, dynamic> && data['message'] != null) {
            message = data['message'];
          } else {
            message = 'An error occurred. Please try again.';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
        message = 'An unexpected error occurred. Please try again.';
        break;
      case DioExceptionType.badCertificate:
        message = 'Bad certificate. Please check your connection security.';
        break;
    }

    debugPrint('Dio error: ${e.message}');
    return Exception(message);
  }

  // Helper methods for offline functionality

  // Get messages from local storage
  Future<List<MessageModel>> _getMessagesFromLocalStorage(String chatId) async {
    try {
      final messagesJson = StorageService.getMessages(chatId) ?? [];
      debugPrint(
        '📱 Repository: Retrieved ${messagesJson.length} messages from local storage',
      );

      final messages = <MessageModel>[];
      for (final messageJson in messagesJson) {
        try {
          final message = MessageModel.fromJson(messageJson);
          messages.add(message);
        } catch (e) {
          debugPrint(
            '❌ Repository: Error parsing message from local storage: $e',
          );
        }
      }

      // Sort by creation date (newest first)
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return messages;
    } catch (e) {
      debugPrint('❌ Repository: Error getting messages from local storage: $e');
      return [];
    }
  }

  // Save a message locally when offline
  Future<MessageModel> _saveOfflineMessage({
    required String chatId,
    required String content,
    List<String>? attachments,
    String? replyToId,
  }) async {
    try {
      // Get current user from storage
      final userData = StorageService.getUserData();
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Create a temporary message ID
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Create message JSON
      final messageJson = {
        '_id': localId,
        'chatId': chatId,
        'content': content,
        'sender': userData,
        'senderId': userData['_id'] ?? userData['id'],
        'type': 'text',
        'attachments':
            attachments
                ?.map(
                  (path) => {
                    'url': path,
                    'type': 'image',
                    'fileName': path.split('/').last,
                  },
                )
                .toList() ??
            [],
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isEdited': false,
        'isDeleted': false,
        'isSynced': false,
        'isLocalOnly': true,
        'localId': localId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      };



      // Add reply info if provided
      if (replyToId != null) {
        messageJson['replyToId'] = replyToId;

        // Try to get the reply message from local storage
        final messagesJson = StorageService.getMessages(chatId) ?? [];
        final replyMessageJson = messagesJson.firstWhere(
          (msg) => msg['_id'] == replyToId || msg['localId'] == replyToId,
          orElse: () => <String, dynamic>{},
        );

        if (replyMessageJson.isNotEmpty) {
          messageJson['replyTo'] = replyMessageJson;
        }
      }

      // Create message model
      final message = MessageModel.fromJson(messageJson);

      // Save to local storage
      await OfflineService().saveOfflineMessage(message);

      return message;
    } catch (e) {
      debugPrint('❌ Repository: Error saving offline message: $e');
      throw Exception('Failed to save offline message: $e');
    }
  }
}
