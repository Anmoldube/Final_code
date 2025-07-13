import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/chat_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/offline_service.dart';
import '../datasources/chat_api_service.dart';

class ChatRepository {
  final ChatApiService _apiService;

  ChatRepository({ChatApiService? apiService})
    : _apiService = apiService ?? ChatApiService();

  // Get all chats for current user
  Future<List<ChatModel>> getAllChats() async {
    try {
      // Check if we're online
      final isOnline = OfflineService().isOnline;

      if (!isOnline) {
        debugPrint(
          '📱 Repository: Device is offline, loading chats from local storage',
        );
        return _getChatsFromLocalStorage();
      }

      debugPrint('🔄 Repository: Getting all chats from server');
      final response = await _apiService.getAllChats();
      debugPrint(
        '📡 Repository: Get chats API response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('📋 Repository: Get chats response data: $data');

        // Handle both possible response formats
        if (data['success'] == true ||
            data['statusCode'] == '10000' ||
            data['statusCode'] == 10000) {
          List<dynamic> chatsJson;

          // Try different response structures
          if (data['data'] != null && data['data'] is List) {
            // Backend returns: { statusCode: "10000", message: "...", data: [...] }
            chatsJson = data['data'] as List<dynamic>;
          } else if (data['chats'] != null) {
            chatsJson = data['chats'] as List<dynamic>;
          } else if (data['data'] != null && data['data']['chats'] != null) {
            chatsJson = data['data']['chats'] as List<dynamic>;
          } else {
            chatsJson = [];
          }

          final chats = <ChatModel>[];
          for (int i = 0; i < chatsJson.length; i++) {
            try {
              final chatJson = chatsJson[i];
              debugPrint(
                '🔄 Repository: Parsing chat $i: ${chatJson['name']} (${chatJson['_id']})',
              );

              // Mark as synced and set sync timestamp
              chatJson['isSynced'] = true;
              chatJson['lastSyncedAt'] = DateTime.now().toIso8601String();
              chatJson['isLocalOnly'] = false;

              final chat = ChatModel.fromJson(chatJson);
              chats.add(chat);
              debugPrint(
                '✅ Repository: Successfully parsed chat: ${chat.name}',
              );
            } catch (e, stackTrace) {
              debugPrint('❌ Repository: Error parsing chat $i: $e');
              debugPrint('📋 Repository: Chat data: ${chatsJson[i]}');
              debugPrint('📋 Repository: Stack trace: $stackTrace');
              // Continue with other chats instead of failing completely
            }
          }

          // Save chats to local storage for offline access
          _saveChatsToLocalStorage(chats);

          print('✅ Repository: Loaded ${chats.length} chats');

          // Save to local storage
          final chatsData = chats.map((chat) => chat.toJson()).toList();
          await StorageService.saveChatsList(chatsData);

          return chats;
        } else {
          print(
            '❌ Repository: Get chats API returned error: ${data['message']}',
          );
          throw Exception(data['message'] ?? 'Failed to load chats');
        }
      } else {
        print(
          '❌ Repository: Get chats bad status code: ${response.statusCode}',
        );
        throw Exception(
          'Failed to load chats with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Repository: Get chats DioException: ${e.message}');
      // Try to load from local storage if network fails
      final localChats = StorageService.getChatsList();
      if (localChats != null) {
        print(
          '📱 Repository: Loaded ${localChats.length} chats from local storage',
        );
        return localChats
            .map((chatData) => ChatModel.fromJson(chatData))
            .toList();
      }
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Repository: Get chats general error: $e');
      debugPrint('Get all chats error: $e');

      // Try to load from local storage
      final localChats = StorageService.getChatsList();
      if (localChats != null) {
        print(
          '📱 Repository: Loaded ${localChats.length} chats from local storage (fallback)',
        );
        return localChats
            .map((chatData) => ChatModel.fromJson(chatData))
            .toList();
      }

      return [];
    }
  }

  // Create or get existing direct chat
  Future<ChatModel> createOrGetDirectChat(String userId) async {
    try {
      print('🔄 Repository: Creating direct chat with user: $userId');
      final response = await _apiService.createOrGetDirectChat(userId);
      print(
        '📡 Repository: Direct chat API response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('📋 Repository: Direct chat response data: $data');

        // Handle both possible response formats
        if (data['success'] == true ||
            data['statusCode'] == '10000' ||
            data['statusCode'] == 10000) {
          dynamic chatJson;

          // Try different response structures
          if (data['chat'] != null) {
            chatJson = data['chat'];
          } else if (data['data'] != null && data['data']['chat'] != null) {
            chatJson = data['data']['chat'];
          } else if (data['data'] != null) {
            chatJson = data['data'];
          } else {
            chatJson = data;
          }

          final chat = ChatModel.fromJson(chatJson);
          print('✅ Repository: Created/found direct chat: ${chat.id}');

          // Save to local storage
          await StorageService.saveChatData(chat.id, chat.toJson());

          return chat;
        } else {
          print(
            '❌ Repository: Direct chat API returned error: ${data['message']}',
          );
          throw Exception(data['message'] ?? 'Failed to create chat');
        }
      } else {
        print(
          '❌ Repository: Direct chat bad status code: ${response.statusCode}',
        );
        throw Exception(
          'Failed to create chat with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Repository: Direct chat DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Repository: Direct chat general error: $e');
      debugPrint('Create or get direct chat error: $e');
      throw Exception('Failed to create chat: $e');
    }
  }

  // Create group chat
  Future<ChatModel> createGroupChat({
    required String name,
    String? description,
    required List<String> participantIds,
  }) async {
    try {
      print(
        '🔄 Repository: Creating group chat: "$name" with ${participantIds.length} participants',
      );
      final response = await _apiService.createGroupChat(
        name: name,
        description: description,
        participantIds: participantIds,
      );
      print(
        '📡 Repository: Group chat API response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('📋 Repository: Group chat response data: $data');

        // Handle both possible response formats
        if (data['success'] == true ||
            data['statusCode'] == '10000' ||
            data['statusCode'] == 10000) {
          dynamic chatJson;

          // Try different response structures
          if (data['chat'] != null) {
            chatJson = data['chat'];
          } else if (data['data'] != null && data['data']['chat'] != null) {
            chatJson = data['data']['chat'];
          } else if (data['data'] != null) {
            chatJson = data['data'];
          } else {
            chatJson = data;
          }

          final chat = ChatModel.fromJson(chatJson);
          print('✅ Repository: Created group chat: ${chat.id}');

          // Save to local storage
          await StorageService.saveChatData(chat.id, chat.toJson());

          return chat;
        } else {
          print(
            '❌ Repository: Group chat API returned error: ${data['message']}',
          );
          throw Exception(data['message'] ?? 'Failed to create group chat');
        }
      } else {
        print(
          '❌ Repository: Group chat bad status code: ${response.statusCode}',
        );
        throw Exception(
          'Failed to create group chat with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Repository: Group chat DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Repository: Group chat general error: $e');
      debugPrint('Create group chat error: $e');
      throw Exception('Failed to create group chat: $e');
    }
  }

  // Get group chat details
  Future<ChatModel> getGroupChatDetails(String chatId) async {
    try {
      final response = await _apiService.getGroupChatDetails(chatId);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final chatJson = data['chat'];
          final chat = ChatModel.fromJson(chatJson);

          // Save to local storage
          await StorageService.saveChatData(chat.id, chat.toJson());

          return chat;
        } else {
          throw Exception(
            data['message'] ?? 'Failed to get group chat details',
          );
        }
      } else {
        throw Exception(
          'Failed to get group chat details with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Try to load from local storage
      final localChatData = StorageService.getChatData(chatId);
      if (localChatData != null) {
        return ChatModel.fromJson(localChatData);
      }
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Get group chat details error: $e');
      throw Exception('Failed to get group chat details: $e');
    }
  }

  // Add user to group chat
  Future<ChatModel> addUserToGroup(String chatId, String userId) async {
    try {
      final response = await _apiService.addUserToGroup(chatId, userId);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final chatJson = data['chat'];
          final chat = ChatModel.fromJson(chatJson);

          // Save to local storage
          await StorageService.saveChatData(chat.id, chat.toJson());

          return chat;
        } else {
          throw Exception(data['message'] ?? 'Failed to add user to group');
        }
      } else {
        throw Exception(
          'Failed to add user to group with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Add user to group error: $e');
      throw Exception('Failed to add user to group: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      final response = await _apiService.deleteChat(chatId);

      if (response.statusCode == 200) {
        // Remove from local storage
        await StorageService.clearMessages(chatId);
      } else {
        throw Exception(
          'Failed to delete chat with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('Delete chat error: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Search chats (local search since API endpoint doesn't exist)
  Future<List<ChatModel>> searchChats(String query) async {
    try {
      print('🔍 Repository: Searching chats locally with query: "$query"');

      // Get all chats first
      final allChats = await getAllChats();

      if (query.isEmpty) {
        return allChats;
      }

      // Filter chats based on query
      final filteredChats = allChats.where((chat) {
        final queryLower = query.toLowerCase();

        // Search in chat name
        if (chat.name.toLowerCase().contains(queryLower) == true) {
          return true;
        }

        // Search in participant names
        for (final participant in chat.participants) {
          if (participant.displayName.toLowerCase().contains(queryLower) ||
              participant.username.toLowerCase().contains(queryLower) ||
              participant.email.toLowerCase().contains(queryLower)) {
            return true;
          }
        }

        return false;
      }).toList();

      print('✅ Repository: Found ${filteredChats.length} matching chats');
      return filteredChats;
    } catch (e) {
      print('❌ Repository: Search chats error: $e');
      debugPrint('Search chats error: $e');
      return [];
    }
  }

  // Get available users for chat creation
  Future<List<UserModel>> getAvailableUsers({String? query}) async {
    try {
      print('🔄 Repository: Getting available users with query: "$query"');
      final response = await _apiService.getAvailableUsers(query: query);
      print('📡 Repository: API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('📋 Repository: Response data: $data');

        // Handle the actual API response structure
        if (data['statusCode'] == '10000' || data['statusCode'] == 10000) {
          // The backend sends { statusCode: "10000", message: "...", data: { users: [...] } }
          final responseData = data['data'];
          if (responseData != null && responseData['users'] != null) {
            final usersJson = responseData['users'] as List<dynamic>;
            final users = usersJson
                .map((userJson) => UserModel.fromJson(userJson))
                .toList();
            print('✅ Repository: Parsed ${users.length} users');
            return users;
          } else if (responseData != null && responseData is List) {
            // Handle case where data is directly an array
            final users = responseData
                .map((userJson) => UserModel.fromJson(userJson))
                .toList();
            print('✅ Repository: Parsed ${users.length} users (direct array)');
            return users;
          } else {
            print(
              '❌ Repository: No users data in response, returning empty array',
            );
            return [];
          }
        } else {
          print(
            '❌ Repository: API returned error status: ${data['statusCode']}, message: ${data['message']}',
          );
          // Don't throw error for "no users found", just return empty array
          if (data['message']?.toString().toLowerCase().contains(
                'no users found',
              ) ==
              true) {
            print('💡 Repository: No users found, returning empty array');
            return [];
          }
          throw Exception(data['message'] ?? 'Failed to get available users');
        }
      } else {
        print('❌ Repository: Bad status code: ${response.statusCode}');
        throw Exception(
          'Failed to get available users with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Repository: DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Repository: General error: $e');
      debugPrint('Get available users error: $e');
      return [];
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _apiService.markChatAsRead(chatId);
    } on DioException catch (e) {
      debugPrint('Mark chat as read error: $e');
      // Don't throw error for this operation
    } catch (e) {
      debugPrint('Mark chat as read error: $e');
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
          message = 'Chat not found.';
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

  // Save chats to local storage
  Future<void> _saveChatsToLocalStorage(List<ChatModel> chats) async {
    try {
      final chatsList = chats.map((chat) => chat.toJson()).toList();
      await StorageService.saveChatsList(chatsList);

      // Also save each chat individually for faster access
      for (final chat in chats) {
        await StorageService.saveChatData(chat.id, chat.toJson());
      }

      debugPrint('✅ Repository: Saved ${chats.length} chats to local storage');
    } catch (e) {
      debugPrint('❌ Repository: Error saving chats to local storage: $e');
    }
  }

  // Get chats from local storage
  Future<List<ChatModel>> _getChatsFromLocalStorage() async {
    try {
      final chatsList = StorageService.getChatsList() ?? [];
      debugPrint(
        '📱 Repository: Retrieved ${chatsList.length} chats from local storage',
      );

      final chats = <ChatModel>[];
      for (final chatJson in chatsList) {
        try {
          final chat = ChatModel.fromJson(chatJson);
          chats.add(chat);
        } catch (e) {
          debugPrint('❌ Repository: Error parsing chat from local storage: $e');
        }
      }

      return chats;
    } catch (e) {
      debugPrint('❌ Repository: Error getting chats from local storage: $e');
      return [];
    }
  }

  // Create a chat in offline mode
  Future<ChatModel> createOfflineChat({
    required String name,
    required String description,
    required ChatType type,
    required List<UserModel> participants,
  }) async {
    try {
      // Generate a temporary local ID
      final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Create a new chat model
      final chat = ChatModel(
        id: localId,
        name: name,
        description: description,
        type: type,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
        isLocalOnly: true,
        lastSyncedAt: DateTime.now(),
      );

      // Save to local storage
      await OfflineService().saveOfflineChat(chat);

      return chat;
    } catch (e) {
      debugPrint('❌ Repository: Error creating offline chat: $e');
      throw Exception('Failed to create offline chat: $e');
    }
  }
}
