import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/file_metadata_model.dart';
import 'storage_service.dart';

class FileMetadataService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/file-metadata';

  /// Helper method to handle token refresh and retry requests
  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(String token) requestFunction,
  ) async {
    final token = await StorageService.getAccessToken();
    if (token == null) throw Exception('No authentication token found');

    var response = await requestFunction(token);

    // Handle token refresh on 401/403 errors
    if (response.statusCode == 401 || response.statusCode == 403) {
      print('🔄 Token expired, attempting refresh...');
      final refreshToken = await StorageService.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          // Try to refresh the token
          final refreshResponse = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refreshToken': refreshToken}),
          ).timeout(ApiConfig.connectTimeout);

          if (refreshResponse.statusCode == 200) {
            final refreshData = json.decode(refreshResponse.body);
            print('🔄 Refresh response: $refreshData');
            
            final tokensData = refreshData['data']['tokens'];
            final newToken = tokensData['accessToken'];
            final newRefreshToken = tokensData['refreshToken'];

            if (newToken == null) {
              throw Exception('No access token in refresh response');
            }

            // Save new tokens
            await StorageService.saveAccessToken(newToken);
            if (newRefreshToken != null) {
              await StorageService.saveRefreshToken(newRefreshToken);
            }

            print('✅ Token refreshed successfully, retrying request...');
            print('🔑 Using new token for retry: ${newToken.substring(0, 50)}...');

            // Retry the original request with new token
            response = await requestFunction(newToken);
          } else {
            print('❌ Token refresh failed with status: ${refreshResponse.statusCode}');
            await StorageService.clearTokens();
            throw Exception('Authentication failed - please login again');
          }
        } catch (refreshError) {
          print('❌ Token refresh error: $refreshError');
          print('❌ Refresh error type: ${refreshError.runtimeType}');
          await StorageService.clearTokens();
          throw Exception('Authentication failed - please login again');
        }
      } else {
        print('❌ No refresh token available');
        await StorageService.clearTokens();
        throw Exception('Authentication failed - please login again');
      }
    }

    return response;
  }

  /// Get file metadata by ID
  static Future<FileMetadataModel?> getFileMetadata(String fileId) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/$fileId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FileMetadataModel.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get file metadata: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting file metadata: $e');
      rethrow;
    }
  }

  /// Get files by message ID
  static Future<List<FileMetadataModel>> getFilesByMessage(String messageId) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$_baseUrl/message/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data'] ?? [];
        return filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
      } else {
        throw Exception('Failed to get files by message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting files by message: $e');
      rethrow;
    }
  }

  /// Get files by chat ID with pagination
  static Future<List<FileMetadataModel>> getFilesByChat(
    String chatId, {
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final uri = Uri.parse('$_baseUrl/chat/$chatId').replace(queryParameters: {
        'limit': limit.toString(),
        'skip': skip.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data'] ?? [];
        return filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
      } else {
        throw Exception('Failed to get files by chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting files by chat: $e');
      rethrow;
    }
  }

  /// Get files by user ID with pagination
  static Future<List<FileMetadataModel>> getFilesByUser(
    String userId, {
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final uri = Uri.parse('$_baseUrl/user/$userId').replace(queryParameters: {
        'limit': limit.toString(),
        'skip': skip.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data'] ?? [];
        return filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
      } else {
        throw Exception('Failed to get files by user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting files by user: $e');
      rethrow;
    }
  }

  /// Search files
  static Future<List<FileMetadataModel>> searchFiles({
    String? searchTerm,
    String? fileType,
    String? chatId,
    String? uploadedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = <String, String>{
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }
      if (fileType != null && fileType.isNotEmpty) {
        queryParams['fileType'] = fileType;
      }
      if (chatId != null && chatId.isNotEmpty) {
        queryParams['chatId'] = chatId;
      }
      if (uploadedBy != null && uploadedBy.isNotEmpty) {
        queryParams['uploadedBy'] = uploadedBy;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String();
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data'] ?? [];
        return filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
      } else {
        throw Exception('Failed to search files: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching files: $e');
      rethrow;
    }
  }

  /// Get file statistics
  static Future<FileStatistics> getFileStatistics({String? userId}) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final queryParams = <String, String>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final uri = Uri.parse('$_baseUrl/stats').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FileStatistics.fromJson(data['data'][0] ?? {});
      } else {
        throw Exception('Failed to get file statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting file statistics: $e');
      rethrow;
    }
  }

  /// Get attachment metadata for multiple files
  static Future<List<FileMetadataModel>> getAttachmentMetadata(
    List<String> attachmentIds,
  ) async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$_baseUrl/attachments/metadata'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'attachmentIds': attachmentIds,
        }),
      ).timeout(ApiConfig.sendTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data'] ?? [];
        return filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
      } else {
        throw Exception('Failed to get attachment metadata: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting attachment metadata: $e');
      rethrow;
    }
  }

  /// Get current user's files
  static Future<List<FileMetadataModel>> getCurrentUserFiles({int limit = 50, int skip = 0}) async {
    try {
      print('🔍 Fetching current user files...');
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      final uri = Uri.parse('$_baseUrl/my-files').replace(queryParameters: queryParams);

      final response = await _makeAuthenticatedRequest((token) async {
        print('🔑 Making request with token: ${token.substring(0, 50)}...');
        return await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(ApiConfig.connectTimeout);
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filesData = data['data']['files'] ?? [];
        final files = filesData.map((file) => FileMetadataModel.fromJson(file)).toList();
        
        print('✅ Successfully fetched ${files.length} files for current user');
        return files;
      } else {
        throw Exception('Failed to fetch current user files: ${response.statusCode}------ backend error ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching current user files: $e');
      rethrow;
    }
  }
}