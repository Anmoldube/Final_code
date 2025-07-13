import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../domain/entities/auth_result.dart';
import '../datasources/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository({AuthApiService? apiService})
    : _apiService = apiService ?? AuthApiService();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Check if we're online
      final isOnline = OfflineService().isOnline;

      if (!isOnline) {
        debugPrint(
          '📱 AuthRepository: Device is offline, attempting offline login',
        );
        return _offlineLogin(email, password);
      }

      debugPrint('🔗 AuthRepository: Making login API call...');
      final response = await _apiService.login(email, password);

      debugPrint('📡 AuthRepository: Response status: ${response.statusCode}');
      debugPrint('📋 AuthRepository: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Handle the actual backend response format
        if (data['statusCode'] == '10000' && data['data'] != null) {
          final responseData = data['data'];
          final userData = responseData['user'];
          final tokens = responseData['tokens'];
          final token = tokens['accessToken'];
          final refreshToken = tokens['refreshToken'];

          debugPrint('👤 AuthRepository: Parsing user data...');

          // Mark user as synced
          userData['isSynced'] = true;
          userData['lastSyncedAt'] = DateTime.now().toIso8601String();

          final user = UserModel.fromJson(userData);

          // Save user data for offline login
          await StorageService.saveUserData(userData);
          await StorageService.saveCredentials(email, password);

          debugPrint('✅ AuthRepository: Login successful, returning result');
          return AuthResult.success(
            user: user,
            token: token,
            refreshToken: refreshToken,
            message: data['message'] ?? 'Login successful',
          );
        } else {
          debugPrint(
            '❌ AuthRepository: Login failed - invalid response format',
          );
          return AuthResult.failure(message: data['message'] ?? 'Login failed');
        }
      } else {
        print(
          '❌ AuthRepository: Login failed - status code: ${response.statusCode}',
        );
        return AuthResult.failure(
          message: 'Login failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ AuthRepository: DioException - $e');
      return _handleDioException(e);
    } catch (e, stackTrace) {
      print('❌ AuthRepository: Unexpected error - $e');
      print('Stack trace: $stackTrace');
      return AuthResult.failure(
        message: 'An unexpected error occurred during login',
      );
    }
  }

  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Check if we're online
      final isOnline = OfflineService().isOnline;

      if (!isOnline) {
        return AuthResult.failure(
          message:
              'Cannot register while offline. Please connect to the internet.',
        );
      }

      final response = await _apiService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        // Handle the actual backend response format
        if (data['statusCode'] == '10000' && data['data'] != null) {
          final responseData = data['data'];
          final userData = responseData['user'];
          final tokens = responseData['tokens'];
          final token = tokens['accessToken'];
          final refreshToken = tokens['refreshToken'];

          // The backend doesn't store firstName and lastName during registration
          // So we need to update the profile after registration to add these fields
          userData['firstName'] = firstName;
          userData['lastName'] = lastName;

          // Mark user as synced
          userData['isSynced'] = true;
          userData['lastSyncedAt'] = DateTime.now().toIso8601String();

          final user = UserModel.fromJson(userData);

          // Save user data for offline login
          await StorageService.saveUserData(userData);
          await StorageService.saveCredentials(email, password);

          // Update profile to add firstName and lastName
          try {
            await _apiService.updateProfile(
              firstName: firstName,
              lastName: lastName,
            );
            debugPrint(
              '✅ AuthRepository: Updated profile with first and last name',
            );
          } catch (e) {
            debugPrint('⚠️ AuthRepository: Failed to update profile: $e');
            // Continue anyway, as the main registration was successful
          }

          return AuthResult.success(
            user: user,
            token: token,
            refreshToken: refreshToken,
            message: data['message'] ?? 'Registration successful',
          );
        } else {
          return AuthResult.failure(
            message: data['message'] ?? 'Registration failed',
          );
        }
      } else {
        return AuthResult.failure(
          message:
              'Registration failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Registration error: $e');
      return AuthResult.failure(
        message: 'An unexpected error occurred during registration',
      );
    }
  }

  Future<AuthResult> logout() async {
    try {
      final response = await _apiService.logout();

      if (response.statusCode == 200) {
        return AuthResult.success(message: 'Logout successful');
      } else {
        // Even if logout fails on server, we'll clear local data
        return AuthResult.success(message: 'Logout completed');
      }
    } on DioException catch (e) {
      debugPrint('Logout error: $e');
      // Even if logout fails, we'll clear local data
      return AuthResult.success(message: 'Logout completed');
    } catch (e) {
      debugPrint('Logout error: $e');
      return AuthResult.success(message: 'Logout completed');
    }
  }

  Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? status,
    String? statusMessage,
  }) async {
    try {
      final response = await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        status: status,
        statusMessage: statusMessage,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final userData = data['user'];
          final user = UserModel.fromJson(userData);

          return AuthResult.success(
            user: user,
            message: data['message'] ?? 'Profile updated successfully',
          );
        } else {
          return AuthResult.failure(
            message: data['message'] ?? 'Profile update failed',
          );
        }
      } else {
        return AuthResult.failure(
          message:
              'Profile update failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Profile update error: $e');
      return AuthResult.failure(
        message: 'An unexpected error occurred during profile update',
      );
    }
  }

  Future<AuthResult> updateAvatar(String avatarPath) async {
    try {
      final response = await _apiService.updateAvatar(avatarPath);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final userData = data['user'];
          final user = UserModel.fromJson(userData);

          return AuthResult.success(
            user: user,
            message: data['message'] ?? 'Avatar updated successfully',
          );
        } else {
          return AuthResult.failure(
            message: data['message'] ?? 'Avatar update failed',
          );
        }
      } else {
        return AuthResult.failure(
          message:
              'Avatar update failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Avatar update error: $e');
      return AuthResult.failure(
        message: 'An unexpected error occurred during avatar update',
      );
    }
  }

  Future<AuthResult> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.refreshToken(refreshToken);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final token = data['accessToken'];
          final newRefreshToken = data['refreshToken'];

          return AuthResult.success(
            token: token,
            refreshToken: newRefreshToken,
            message: data['message'] ?? 'Token refreshed successfully',
          );
        } else {
          return AuthResult.failure(
            message: data['message'] ?? 'Token refresh failed',
          );
        }
      } else {
        return AuthResult.failure(
          message:
              'Token refresh failed with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return AuthResult.failure(
        message: 'An unexpected error occurred during token refresh',
      );
    }
  }

  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          final userData = data['user'];
          final user = UserModel.fromJson(userData);

          return AuthResult.success(
            user: user,
            message: data['message'] ?? 'User data retrieved successfully',
          );
        } else {
          return AuthResult.failure(
            message: data['message'] ?? 'Failed to retrieve user data',
          );
        }
      } else {
        return AuthResult.failure(
          message:
              'Failed to retrieve user data with status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Get current user error: $e');
      return AuthResult.failure(
        message: 'An unexpected error occurred while retrieving user data',
      );
    }
  }

  AuthResult _handleDioException(DioException e) {
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
          message =
              'Invalid credentials. Please check your email and password.';
        } else if (statusCode == 403) {
          message = 'Access denied. Please contact support.';
        } else if (statusCode == 404) {
          message = 'Service not found. Please try again later.';
        } else if (statusCode == 422) {
          if (data is Map<String, dynamic> && data['message'] != null) {
            message = data['message'];
          } else if (data is Map<String, dynamic> && data['errors'] != null) {
            final errors = data['errors'] as List<dynamic>;
            message = errors.isNotEmpty
                ? errors.first['msg'] ?? 'Validation error'
                : 'Validation error';
          } else {
            message = 'Invalid input. Please check your data.';
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
    return AuthResult.failure(message: message);
  }

  // Helper methods for offline functionality

  // Offline login
  Future<AuthResult> _offlineLogin(String email, String password) async {
    try {
      // Get saved credentials
      final savedCredentials = await StorageService.getCredentials();
      if (savedCredentials == null) {
        return AuthResult.failure(
          message:
              'No saved credentials found. Please connect to the internet to login.',
        );
      }

      final savedEmail = savedCredentials['email'];
      final savedPassword = savedCredentials['password'];

      // Check if credentials match
      if (email != savedEmail || password != savedPassword) {
        return AuthResult.failure(
          message: 'Invalid credentials. Please check your email and password.',
        );
      }

      // Get saved user data
      final userData = StorageService.getUserData();
      if (userData == null) {
        return AuthResult.failure(
          message:
              'No saved user data found. Please connect to the internet to login.',
        );
      }

      // Create user model
      final user = UserModel.fromJson(userData);

      // Create a dummy token for offline mode
      const offlineToken = 'offline_token';

      debugPrint('✅ AuthRepository: Offline login successful');
      return AuthResult.success(
        user: user,
        token: offlineToken,
        refreshToken: offlineToken,
        message: 'Offline login successful',
        isOfflineLogin: true,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Offline login error: $e');
      return AuthResult.failure(message: 'Failed to login offline: $e');
    }
  }

  // Save credentials for offline login
  Future<void> _saveCredentials(String email, String password) async {
    await StorageService.saveCredentials(email, password);
  }
}
