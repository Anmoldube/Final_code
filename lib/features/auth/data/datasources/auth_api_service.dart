import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/config/api_config.dart';

class AuthApiService {
  late final Dio _dio;

  AuthApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
        // Enable cookie support for authentication
        extra: {'withCredentials': true},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());

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

  Future<Response> login(String email, String password) async {
    return await _dio.post(
      '/auth/login',
      data: {
        'userId': email,
        'password': password,
      }, // userId can be email or username
    );
  }

  Future<Response> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        // These fields are not used by the backend but we'll keep them for future compatibility
        'firstName': firstName,
        'lastName': lastName,
      },
    );
  }

  Future<Response> logout() async {
    return await _dio.post('/auth/logout');
  }

  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? status,
    String? statusMessage,
  }) async {
    final data = <String, dynamic>{};

    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (status != null) data['status'] = status;
    if (statusMessage != null) data['statusMessage'] = statusMessage;

    return await _dio.put('/auth/profile', data: data);
  }

  Future<Response> updateAvatar(String avatarPath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(avatarPath),
    });

    return await _dio.post('/auth/avatar', data: formData);
  }

  Future<Response> refreshToken(String refreshToken) async {
    return await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/profile');
  }

  Future<Response> forgotPassword(String email) async {
    return await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<Response> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return await _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'password': newPassword},
    );
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _dio.post(
      '/users/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<Response> verifyEmail(String token) async {
    return await _dio.post('/auth/verify-email', data: {'token': token});
  }

  Future<Response> resendVerification(String email) async {
    return await _dio.post('/auth/resend-verification', data: {'email': email});
  }
}

// Interceptor for handling authentication
class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authentication token to requests
    final token = await StorageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle token refresh on 401 errors
    if (err.response?.statusCode == 401) {
      final refreshToken = await StorageService.getRefreshToken();

      if (refreshToken != null) {
        try {
          // Try to refresh the token
          final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
          final response = await dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200) {
            final data = response.data;
            final newToken = data['accessToken'];
            final newRefreshToken = data['refreshToken'];

            // Save new tokens
            await StorageService.saveAccessToken(newToken);
            if (newRefreshToken != null) {
              await StorageService.saveRefreshToken(newRefreshToken);
            }

            // Retry the original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (e) {
          // Token refresh failed, clear tokens
          await StorageService.clearTokens();
          debugPrint('Token refresh failed: $e');
        }
      }
    }

    handler.next(err);
  }
}

// Network info helper
class NetworkInfo {
  static String getBaseUrl() {
    // You can implement logic here to determine the base URL
    // For example, check if on LAN vs internet

    if (kDebugMode) {
      // For development, use LAN IP for testing
      return '${ApiConfig.baseUrl}/api';
    } else {
      // For production, use your actual server URL
      return 'https://your-domain.com/api';
    }
  }

  static bool isLocalNetwork(String url) {
    return url.contains('localhost') ||
        url.contains('127.0.0.1') ||
        url.contains('192.168.') ||
        url.contains('10.0.') ||
        url.contains('172.');
  }
}
