import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import 'storage_service.dart';
import 'enhanced_auth_service.dart';
import '../config/api_config.dart';

/// Comprehensive auth debugging helper
class AuthDebugHelper {
  /// Run complete authentication diagnostic
  static Future<void> runFullDiagnostic() async {
    debugPrint('🔍 ===== AUTHENTICATION FULL DIAGNOSTIC START =====');

    await _testStorageService();
    await _testTokenStatus();
    await _testBackendConnection();
    await _testAuthenticatedEndpoint();
    await _testTokenRefresh();

    debugPrint('🔍 ===== AUTHENTICATION FULL DIAGNOSTIC END =====');
  }

  /// Test storage service functionality
  static Future<void> _testStorageService() async {
    debugPrint('\n📱 [DIAGNOSTIC] Testing Storage Service...');

    try {
      final accessToken = await StorageService.getAccessToken();
      final refreshToken = await StorageService.getRefreshToken();
      final userId = StorageService.getUserId();
      final userData = StorageService.getUserData();
      final isLoggedIn = await StorageService.isLoggedIn();

      debugPrint('📱 [DIAGNOSTIC] Storage Results:');
      debugPrint(
        '📱   - Has Access Token: ${accessToken != null} (${accessToken?.length ?? 0} chars)',
      );
      debugPrint('📱   - Has Refresh Token: ${refreshToken != null}');
      debugPrint('📱   - User ID: $userId');
      debugPrint(
        '📱   - User Data: ${userData != null ? 'Present' : 'Missing'}',
      );
      debugPrint('📱   - Is Logged In: $isLoggedIn');

      if (accessToken != null) {
        debugPrint(
          '📱   - Access Token Preview: ${accessToken.length > 50 ? '${accessToken.substring(0, 50)}...' : accessToken}',
        );
      }

      final dbInfo = await StorageService.getDatabaseInfo();
      debugPrint('📱   - Database Info: $dbInfo');
    } catch (e, stackTrace) {
      debugPrint('📱 ❌ [DIAGNOSTIC] Storage Service Error: $e');
      debugPrint('📱 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test token status and validation
  static Future<void> _testTokenStatus() async {
    debugPrint('\n🔐 [DIAGNOSTIC] Testing Token Status...');

    try {
      final tokenStatus = await EnhancedAuthService.checkTokenStatus();
      debugPrint('🔐 [DIAGNOSTIC] Token Status: ${tokenStatus.name}');

      final debugInfo = await EnhancedAuthService.getAuthDebugInfo();
      debugPrint('🔐 [DIAGNOSTIC] Auth Debug Info:');
      for (final entry in debugInfo.entries) {
        debugPrint('🔐   - ${entry.key}: ${entry.value}');
      }
    } catch (e, stackTrace) {
      debugPrint('🔐 ❌ [DIAGNOSTIC] Token Status Error: $e');
      debugPrint('🔐 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  ///  
  static Future<void> _testBackendConnection() async {
    debugPrint('\n🌐 [DIAGNOSTIC] Testing Backend Connection...');

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint('🌐 [DIAGNOSTIC] Connecting to: ${ApiConfig.baseUrl}');

      // Test basic connectivity
      try {
        final response = await dio.get('/health');
        debugPrint(
          '🌐 ✅ [DIAGNOSTIC] Backend health check: ${response.statusCode}',
        );
      } catch (healthError) {
        debugPrint('🌐 ⚠️ [DIAGNOSTIC] Health endpoint failed: $healthError');
        // Try a different endpoint
        try {
          final response = await dio.get('/');
          debugPrint('🌐 ✅ [DIAGNOSTIC] Root endpoint: ${response.statusCode}');
        } catch (rootError) {
          debugPrint('🌐 ❌ [DIAGNOSTIC] Root endpoint failed: $rootError');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🌐 ❌ [DIAGNOSTIC] Backend Connection Error: $e');
      debugPrint('🌐 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test authenticated endpoint
  static Future<void> _testAuthenticatedEndpoint() async {
    debugPrint('\n🔒 [DIAGNOSTIC] Testing Authenticated Endpoint...');

    try {
      final success = await EnhancedAuthService.testAuthenticatedCall();
      debugPrint('🔒 [DIAGNOSTIC] Authenticated call result: $success');

      // Manual test with current token
      final token = await StorageService.getAccessToken();
      if (token != null) {
        final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

        try {
          final response = await dio.get(
            '/auth/profile',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          debugPrint(
            '🔒 [DIAGNOSTIC] Manual auth test - Status: ${response.statusCode}',
          );
          debugPrint(
            '🔒 [DIAGNOSTIC] Manual auth test - Data: ${response.data}',
          );
        } catch (authError) {
          debugPrint('🔒 ❌ [DIAGNOSTIC] Manual auth test failed: $authError');
          if (authError is DioException) {
            debugPrint(
              '🔒 ❌ [DIAGNOSTIC] Auth error status: ${authError.response?.statusCode}',
            );
            debugPrint(
              '🔒 ❌ [DIAGNOSTIC] Auth error data: ${authError.response?.data}',
            );
          }
        }
      } else {
        debugPrint('🔒 ❌ [DIAGNOSTIC] No token available for manual test');
      }
    } catch (e, stackTrace) {
      debugPrint('🔒 ❌ [DIAGNOSTIC] Authenticated Endpoint Error: $e');
      debugPrint('🔒 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test token refresh functionality
  static Future<void> _testTokenRefresh() async {
    debugPrint('\n🔄 [DIAGNOSTIC] Testing Token Refresh...');

    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        debugPrint('🔄 ❌ [DIAGNOSTIC] No refresh token available');
        return;
      }

      debugPrint(
        '🔄 [DIAGNOSTIC] Refresh token available, testing refresh endpoint...',
      );

      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

      try {
        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        debugPrint(
          '🔄 [DIAGNOSTIC] Refresh test - Status: ${response.statusCode}',
        );
        debugPrint('🔄 [DIAGNOSTIC] Refresh test - Data: ${response.data}');

        if (response.statusCode == 200) {
          debugPrint('🔄 ✅ [DIAGNOSTIC] Refresh endpoint is working correctly');
        } else {
          debugPrint('🔄 ❌ [DIAGNOSTIC] Refresh endpoint returned error');
        }
      } catch (refreshError) {
        debugPrint(
          '🔄 ❌ [DIAGNOSTIC] Refresh endpoint test failed: $refreshError',
        );
        if (refreshError is DioException) {
          debugPrint(
            '🔄 ❌ [DIAGNOSTIC] Refresh error status: ${refreshError.response?.statusCode}',
          );
          debugPrint(
            '🔄 ❌ [DIAGNOSTIC] Refresh error data: ${refreshError.response?.data}',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('🔄 ❌ [DIAGNOSTIC] Token Refresh Error: $e');
      debugPrint('🔄 📚 [DIAGNOSTIC] Stack trace: $stackTrace');
    }
  }

  /// Test specific API endpoint that's failing
  static Future<void> testSpecificEndpoint(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    debugPrint('\n🎯 [DIAGNOSTIC] Testing Specific Endpoint: $endpoint');

    try {
      final token = await StorageService.getAccessToken();
      final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

      // Add enhanced auth interceptor
      dio.interceptors.add(EnhancedAuthInterceptor());

      debugPrint('🎯 [DIAGNOSTIC] Making $method request to: $endpoint');
      debugPrint(
        '🎯 [DIAGNOSTIC] With token: ${token != null ? 'Present' : 'Missing'}',
      );
      debugPrint('🎯 [DIAGNOSTIC] Data: $data');

      Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await dio.get(endpoint);
          break;
        case 'POST':
          response = await dio.post(endpoint, data: data);
          break;
        case 'PUT':
          response = await dio.put(endpoint, data: data);
          break;
        case 'DELETE':
          response = await dio.delete(endpoint, data: data);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint(
        '🎯 ✅ [DIAGNOSTIC] Request successful - Status: ${response.statusCode}',
      );
      debugPrint('🎯 📋 [DIAGNOSTIC] Response data: ${response.data}');
    } catch (e, stackTrace) {
      debugPrint('🎯 ❌ [DIAGNOSTIC] Endpoint test failed: $e');
      debugPrint('🎯 📚 [DIAGNOSTIC] Stack trace: $stackTrace');

      if (e is DioException) {
        debugPrint('🎯 🌐 [DIAGNOSTIC] Dio Error Details:');
        debugPrint('🎯   - Status: ${e.response?.statusCode}');
        debugPrint('🎯   - Data: ${e.response?.data}');
        debugPrint('🎯   - Headers: ${e.response?.headers}');
      }
    }
  }

  /// Quick fix for common auth issues
  static Future<void> quickFix() async {
    debugPrint('\n🛠️ [QUICK FIX] Starting automated fix...');

    try {
      // Step 1: Check if tokens exist
      final hasAccessToken = await StorageService.getAccessToken() != null;
      final hasRefreshToken = await StorageService.getRefreshToken() != null;

      if (!hasAccessToken && !hasRefreshToken) {
        debugPrint('🛠️ ❌ [QUICK FIX] No tokens found - user needs to login');
        return;
      }

      // Step 2: Try to refresh token
      if (hasRefreshToken) {
        debugPrint('🛠️ 🔄 [QUICK FIX] Attempting token refresh...');
        final refreshed = await EnhancedAuthService.forceRefreshToken();

        if (refreshed) {
          debugPrint('🛠️ ✅ [QUICK FIX] Token refreshed successfully!');
          debugPrint('🛠️ 🎉 [QUICK FIX] Try your request again now');
          return;
        }
      }

      // Step 3: Clear invalid tokens
      debugPrint('🛠️ 🧹 [QUICK FIX] Clearing invalid tokens...');
      await StorageService.clearTokens();
      debugPrint(
        '🛠️ ✅ [QUICK FIX] Tokens cleared - user needs to login again',
      );
    } catch (e, stackTrace) {
      debugPrint('🛠️ ❌ [QUICK FIX] Error: $e');
      debugPrint('🛠️ 📚 [QUICK FIX] Stack trace: $stackTrace');
    }
  }
}
