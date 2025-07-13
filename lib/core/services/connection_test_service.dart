import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ConnectionTestService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: ApiConfig.defaultHeaders,
    ),
  );

  /// Test basic connection to the backend
  static Future<bool> testConnection() async {
    try {
      debugPrint('Testing connection to: ${ApiConfig.baseUrl}');

      final response = await _dio.get('/health');

      if (response.statusCode == 200) {
        debugPrint('✅ Backend connection successful');
        debugPrint('Response: ${response.data}');
        return true;
      } else {
        debugPrint(
          '❌ Backend connection failed with status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Backend connection error: $e');
      return false;
    }
  }

  /// Test authentication endpoints
  static Future<Map<String, bool>> testAuthEndpoints() async {
    final results = <String, bool>{};

    try {
      // Test register endpoint (should return validation error for empty data)
      try {
        await _dio.post('/auth/register', data: {});
        results['register'] = false; // Should not succeed with empty data
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          results['register'] = true; // Validation error is expected
        } else {
          results['register'] = false;
        }
      }

      // Test login endpoint (should return validation error for empty data)
      try {
        await _dio.post('/auth/login', data: {});
        results['login'] = false; // Should not succeed with empty data
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          results['login'] = true; // Validation error is expected
        } else {
          results['login'] = false;
        }
      }

      debugPrint('Auth endpoints test results: $results');
      return results;
    } catch (e) {
      debugPrint('Auth endpoints test error: $e');
      return results;
    }
  }

  /// Test chat endpoints (requires authentication)
  static Future<Map<String, bool>> testChatEndpoints(String token) async {
    final results = <String, bool>{};

    final authDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    try {
      // Test get chats endpoint
      try {
        final response = await authDio.get('/api/chat');
        results['getChats'] = response.statusCode == 200;
      } catch (e) {
        results['getChats'] = false;
      }

      // Test get users endpoint
      try {
        final response = await authDio.get('/api/chat/users');
        results['getUsers'] = response.statusCode == 200;
      } catch (e) {
        results['getUsers'] = false;
      }

      debugPrint('Chat endpoints test results: $results');
      return results;
    } catch (e) {
      debugPrint('Chat endpoints test error: $e');
      return results;
    }
  }

  /// Test message endpoints (requires authentication)
  static Future<Map<String, bool>> testMessageEndpoints(String token) async {
    final results = <String, bool>{};

    final authDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      ),
    );

    try {
      // Test get unread messages endpoint
      try {
        final response = await authDio.get('/api/messages/unread');
        results['getUnreadMessages'] = response.statusCode == 200;
      } catch (e) {
        results['getUnreadMessages'] = false;
      }

      debugPrint('Message endpoints test results: $results');
      return results;
    } catch (e) {
      debugPrint('Message endpoints test error: $e');
      return results;
    }
  }

  /// Comprehensive connection test
  static Future<Map<String, dynamic>> runFullConnectionTest({
    String? token,
  }) async {
    final results = <String, dynamic>{};

    debugPrint('🔄 Starting comprehensive backend connection test...');

    // Test basic connection
    results['basicConnection'] = await testConnection();

    // Test auth endpoints
    results['authEndpoints'] = await testAuthEndpoints();

    // If token is provided, test authenticated endpoints
    if (token != null && token.isNotEmpty) {
      results['chatEndpoints'] = await testChatEndpoints(token);
      results['messageEndpoints'] = await testMessageEndpoints(token);
    }

    debugPrint('🏁 Connection test completed');
    debugPrint('Results: $results');

    return results;
  }

  /// Get backend info
  static Map<String, String> getBackendInfo() {
    return {
      'baseUrl': ApiConfig.baseUrl,
      'socketUrl': ApiConfig.socketUrl,
      'authEndpoint': ApiConfig.authEndpoint,
      'chatEndpoint': ApiConfig.chatEndpoint,
      'messageEndpoint': ApiConfig.messageEndpoint,
    };
  }
}
