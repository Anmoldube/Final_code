import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'storage_service.dart';
import '../config/api_config.dart';

/// Enhanced authentication service with better debugging and token management
class EnhancedAuthService {
  static late final Dio _dio;

  static void initialize() {
    _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  }

  /// Check if the current access token is valid (not expired)
  static Future<TokenStatus> checkTokenStatus() async {
    try {
      debugPrint('🔐 [checkTokenStatus] Starting token validation...');
      final accessToken = await StorageService.getAccessToken();
      if (accessToken == null) {
        debugPrint('🔐 ❌ [checkTokenStatus] No access token found in storage');
        return TokenStatus.missing;
      }

      debugPrint(
        '🔐 ✅ [checkTokenStatus] Access token found (length: ${accessToken.length})',
      );
      debugPrint(
        '🔐 🔍 [checkTokenStatus] Token preview: ${accessToken.length > 50 ? '${accessToken.substring(0, 50)}...' : accessToken}',
      );

      // Check if token is expired
      try {
        final isExpired = JwtDecoder.isExpired(accessToken);
        debugPrint('🔐 📅 [checkTokenStatus] Token expired check: $isExpired');

        if (isExpired) {
          debugPrint('🔐 ❌ [checkTokenStatus] Access token is expired');
          return TokenStatus.expired;
        }
      } catch (jwtError) {
        debugPrint('🔐 ❌ [checkTokenStatus] JWT decode error: $jwtError');
        debugPrint('🔐 🔍 [checkTokenStatus] Invalid token format detected');
        return TokenStatus.invalid;
      }

      try {
        // Get token expiry time
        final expiryDate = JwtDecoder.getExpirationDate(accessToken);
        final timeUntilExpiry = expiryDate.difference(DateTime.now());
        debugPrint(
          '🔐 📅 [checkTokenStatus] Token expires at: ${expiryDate.toLocal()}',
        );
        debugPrint(
          '🔐 ⏰ [checkTokenStatus] Time until expiry: ${timeUntilExpiry.inMinutes} minutes',
        );

        if (timeUntilExpiry.inMinutes < 5) {
          debugPrint(
            '🔐 ⚠️ [checkTokenStatus] Token expires soon, should refresh',
          );
          return TokenStatus.expiringSoon;
        }

        debugPrint('🔐 ✅ [checkTokenStatus] Token is valid');
        return TokenStatus.valid;
      } catch (dateError) {
        debugPrint(
          '🔐 ❌ [checkTokenStatus] Error parsing token date: $dateError',
        );
        return TokenStatus.invalid;
      }
    } catch (e, stackTrace) {
      debugPrint('🔐 ❌ [checkTokenStatus] Critical error: $e');
      debugPrint('🔐 📚 [checkTokenStatus] Stack trace: $stackTrace');
      return TokenStatus.invalid;
    }
  }

  /// Force refresh the access token
  static Future<bool> forceRefreshToken() async {
    try {
      debugPrint('🔄 [forceRefreshToken] Starting token refresh process...');

      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        debugPrint(
          '🔄 ❌ [forceRefreshToken] No refresh token available in storage',
        );
        return false;
      }

      debugPrint('🔄 ✅ [forceRefreshToken] Refresh token found');
      debugPrint(
        '🔄 🌐 [forceRefreshToken] Making request to: ${ApiConfig.baseUrl}/auth/refresh',
      );

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint(
        '🔄 📡 [forceRefreshToken] Response status: ${response.statusCode}',
      );
      debugPrint('🔄 📋 [forceRefreshToken] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        // Extract tokens from the nested data structure
        final tokens = data['data']?['tokens'];
        final newAccessToken = tokens?['accessToken'];
        final newRefreshToken = tokens?['refreshToken'];

        debugPrint(
          '🔄 📊 [forceRefreshToken] New tokens - Access: ${newAccessToken != null ? 'Present' : 'Missing'}, Refresh: ${newRefreshToken != null ? 'Present' : 'Missing'}',
        );

        if (newAccessToken != null) {
          await StorageService.saveAccessToken(newAccessToken);
          debugPrint('🔄 ✅ [forceRefreshToken] New access token saved');
        } else {
          debugPrint('🔄 ❌ [forceRefreshToken] No access token in response!');
          return false;
        }

        if (newRefreshToken != null) {
          await StorageService.saveRefreshToken(newRefreshToken);
          debugPrint('🔄 ✅ [forceRefreshToken] New refresh token saved');
        }

        debugPrint(
          '🔄 🎉 [forceRefreshToken] Token refresh completed successfully!',
        );
        return true;
      } else {
        debugPrint(
          '🔄 ❌ [forceRefreshToken] Unexpected response status: ${response.statusCode}',
        );
        debugPrint('🔄 📋 [forceRefreshToken] Response body: ${response.data}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('🔄 ❌ [forceRefreshToken] Token refresh failed: $e');
      debugPrint('🔄 📚 [forceRefreshToken] Stack trace: $stackTrace');

      if (e is DioException) {
        debugPrint('🔄 🌐 [forceRefreshToken] Dio Error Details:');
        debugPrint('🔄   - Type: ${e.type}');
        debugPrint('🔄   - Message: ${e.message}');
        debugPrint('🔄   - Status: ${e.response?.statusCode}');
        debugPrint('🔄   - Data: ${e.response?.data}');

        if (e.response?.statusCode == 401) {
          debugPrint(
            '🔄 🔄 [forceRefreshToken] Refresh token expired, clearing tokens',
          );
          await StorageService.clearTokens();
        }
      }
    }
    return false;
  }

  /// Test authenticated API call
  static Future<bool> testAuthenticatedCall() async {
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        debugPrint('❌ No token available for test');
        return false;
      }

      final response = await _dio.get(
        '/auth/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Authenticated call successful: ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('❌ Authenticated call failed: $e');
      return false;
    }
  }

  /// Get detailed authentication debug info
  static Future<Map<String, dynamic>> getAuthDebugInfo() async {
    final info = <String, dynamic>{};

    // Token status
    final tokenStatus = await checkTokenStatus();
    info['token_status'] = tokenStatus.name;

    // Token details
    final accessToken = await StorageService.getAccessToken();
    if (accessToken != null) {
      try {
        final decodedToken = JwtDecoder.decode(accessToken);
        info['token_payload'] = decodedToken;
        info['token_expiry'] = JwtDecoder.getExpirationDate(
          accessToken,
        ).toIso8601String();

        // Get issued at time from payload if available
        if (decodedToken['iat'] != null) {
          final iat = decodedToken['iat'] as int;
          final issuedAt = DateTime.fromMillisecondsSinceEpoch(iat * 1000);
          info['token_issued_at'] = issuedAt.toIso8601String();
        }
      } catch (e) {
        info['token_decode_error'] = e.toString();
      }
    }

    // Storage info
    info['has_access_token'] = accessToken != null;
    info['has_refresh_token'] = await StorageService.getRefreshToken() != null;
    info['user_id'] = StorageService.getUserId();
    info['storage_info'] = await StorageService.getDatabaseInfo();

    return info;
  }

  /// Force logout and clear all authentication data
  static Future<void> forceLogout() async {
    debugPrint('🚪 Force logout - clearing all auth data');
    await StorageService.clearAllData();
  }
}

enum TokenStatus { missing, invalid, expired, expiringSoon, valid }

/// Enhanced auth interceptor with better error handling
class EnhancedAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    debugPrint('🌐 [AuthInterceptor] ===== REQUEST START =====');
    debugPrint(
      '🌐 [AuthInterceptor] Making request to: ${options.baseUrl}${options.path}',
    );
    debugPrint('🌐 [AuthInterceptor] Method: ${options.method}');
    debugPrint(
      '🌐 [AuthInterceptor] Current headers: ${options.headers.keys.toList()}',
    );

    // Check token status before making request
    final tokenStatus = await EnhancedAuthService.checkTokenStatus();
    debugPrint('🔐 [AuthInterceptor] Token status: ${tokenStatus.name}');

    switch (tokenStatus) {
      case TokenStatus.missing:
        debugPrint(
          '🔐 ❌ [AuthInterceptor] No token available - user needs to login',
        );
        break;
      case TokenStatus.expired:
        debugPrint(
          '🔐 🔄 [AuthInterceptor] Token expired, attempting refresh...',
        );
        final refreshed = await EnhancedAuthService.forceRefreshToken();
        if (!refreshed) {
          debugPrint(
            '🔐 ❌ [AuthInterceptor] Token refresh failed - user needs to re-login',
          );
          break;
        }
        debugPrint('🔐 ✅ [AuthInterceptor] Token refreshed successfully');
        break;
      case TokenStatus.expiringSoon:
        debugPrint(
          '🔐 ⚠️ [AuthInterceptor] Token expires soon, will refresh after request',
        );
        _refreshInBackground();
        break;
      case TokenStatus.valid:
        debugPrint('🔐 ✅ [AuthInterceptor] Token is valid');
        break;
      case TokenStatus.invalid:
        debugPrint('🔐 ❌ [AuthInterceptor] Token is invalid');
        break;
    }

    // Add token to request if available
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('🔐 ✅ [AuthInterceptor] Added Authorization header');
      debugPrint(
        '🔐 🔍 [AuthInterceptor] Token preview: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
      );
    } else {
      debugPrint('🔐 ❌ [AuthInterceptor] No token to add to request!');
      debugPrint(
        '🔐 ⚠️ [AuthInterceptor] This request will likely fail with 401',
      );
    }

    debugPrint(
      '🌐 [AuthInterceptor] Final headers: ${options.headers.keys.toList()}',
    );
    debugPrint(
      '🌐 [AuthInterceptor] Has Authorization: ${options.headers.containsKey('Authorization')}',
    );
    debugPrint('🌐 [AuthInterceptor] ===== REQUEST END =====');

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('🌐 [AuthInterceptor] ===== ERROR HANDLING START =====');
    debugPrint('🌐 [AuthInterceptor] Request error details:');
    debugPrint(
      '🌐   - URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}',
    );
    debugPrint('🌐   - Method: ${err.requestOptions.method}');
    debugPrint('🌐   - Status: ${err.response?.statusCode}');
    debugPrint('🌐   - Message: ${err.message}');
    debugPrint('🌐   - Response data: ${err.response?.data}');
    debugPrint(
      '🌐   - Had Authorization header: ${err.requestOptions.headers.containsKey('Authorization')}',
    );

    if (err.response?.statusCode == 401) {
      debugPrint('🔐 [AuthInterceptor] Got 401 Unauthorized error');
      debugPrint('🔐 [AuthInterceptor] Attempting automatic token refresh...');

      final refreshed = await EnhancedAuthService.forceRefreshToken();
      if (refreshed) {
        debugPrint(
          '🔐 ✅ [AuthInterceptor] Token refreshed successfully, retrying request...',
        );

        // Retry the original request with new token
        final token = await StorageService.getAccessToken();
        if (token != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $token';
          debugPrint(
            '🔐 🔄 [AuthInterceptor] Retrying with new token: ${token.substring(0, 20)}...',
          );

          try {
            final retryDio = Dio(BaseOptions(baseUrl: options.baseUrl));
            final response = await retryDio.fetch(options);
            debugPrint('🔐 ✅ [AuthInterceptor] Retry successful!');
            return handler.resolve(response);
          } catch (retryError) {
            debugPrint(
              '🔐 ❌ [AuthInterceptor] Retry attempt failed: $retryError',
            );
            if (retryError is DioException) {
              debugPrint(
                '🔐 ❌ [AuthInterceptor] Retry error status: ${retryError.response?.statusCode}',
              );
              debugPrint(
                '🔐 ❌ [AuthInterceptor] Retry error data: ${retryError.response?.data}',
              );
            }
          }
        } else {
          debugPrint(
            '🔐 ❌ [AuthInterceptor] No token available after refresh!',
          );
        }
      } else {
        debugPrint(
          '🔐 ❌ [AuthInterceptor] Token refresh failed - user needs to re-login',
        );
      }
    } else {
      debugPrint(
        '🌐 [AuthInterceptor] Non-401 error, passing through: ${err.response?.statusCode}',
      );
    }

    debugPrint('🌐 [AuthInterceptor] ===== ERROR HANDLING END =====');
    handler.next(err);
  }

  void _refreshInBackground() {
    // Refresh token in background without blocking current request
    Future.delayed(Duration.zero, () async {
      await EnhancedAuthService.forceRefreshToken();
    });
  }
}
