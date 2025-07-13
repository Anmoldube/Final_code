import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/models/user_status.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(const AuthState());

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      print('🔄 Initializing auth state...');
      final isLoggedIn = await StorageService.isLoggedIn();
      print('📱 Storage check: isLoggedIn=$isLoggedIn');

      if (isLoggedIn) {
        final userData = StorageService.getUserData();
        print(
          '👤 User data from storage: ${userData != null ? 'found' : 'not found'}',
        );

        if (userData != null) {
          final user = UserModel.fromJson(userData);
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            isLoading: false,
          );
          
          // Update ChatModel's currentUserId for proper user context
          ChatModel.currentUserId = user.id;
          
          print(
            '✅ Auth initialized: User ${user.username} restored from storage',
          );
        } else {
          print('⚠️ No user data found, logging out');
          await logout();
        }
      } else {
        state = state.copyWith(isLoading: false);
        print('❌ User not logged in');
      }
    } catch (e, stackTrace) {
      print('❌ Auth initialization error: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    print('🔐 Starting login process for: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📡 Calling auth repository login...');
      final result = await _authRepository.login(
        email: email,
        password: password,
      );

      print(
        '📋 Login result: success=${result.success}, user=${result.user?.username}, token=${result.token != null ? 'present' : 'null'}',
      );

      if (result.success && result.user != null && result.token != null) {
        print('💾 Saving tokens and user data...');

        // Save tokens
        await StorageService.saveAccessToken(result.token!);
        if (result.refreshToken != null) {
          await StorageService.saveRefreshToken(result.refreshToken!);
        }

        // Save user data
        await StorageService.saveUserId(result.user!.id);
        await StorageService.saveUserData(result.user!.toJson());

        print('🔄 Updating auth state...');
        // Update state
        state = state.copyWith(
          isAuthenticated: true,
          user: result.user,
          isLoading: false,
          error: null,
        );

        // Update ChatModel's currentUserId for proper user context
        ChatModel.currentUserId = result.user!.id;

        print(
          '✅ Login successful: User ${result.user!.username} authenticated',
        );
        print(
          '🔐 Auth state updated: isAuthenticated=${state.isAuthenticated}',
        );

        // Show success notification
        _ref.read(inAppNotificationServiceProvider.notifier).showLoginSuccess(
          result.user!.username,
        );
      } else {
        print(
          '❌ Login failed: success=${result.success}, message=${result.message}',
        );
        throw Exception(result.message ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      print('❌ Login error: $e');
      print('Stack trace: $stackTrace');
      
      // Show error notification
      _ref.read(inAppNotificationServiceProvider.notifier).showError(
        'Login Failed',
        _getLoginErrorMessage(e.toString()),
      );
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
      rethrow;
    }
  }

  // Register
  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );

      if (result.success && result.user != null && result.token != null) {
        // Save tokens
        await StorageService.saveAccessToken(result.token!);
        if (result.refreshToken != null) {
          await StorageService.saveRefreshToken(result.refreshToken!);
        }

        // Save user data
        await StorageService.saveUserId(result.user!.id);
        await StorageService.saveUserData(result.user!.toJson());

        // Update state
        state = state.copyWith(
          isAuthenticated: true,
          user: result.user,
          isLoading: false,
          error: null,
        );

        // Update ChatModel's currentUserId for proper user context
        ChatModel.currentUserId = result.user!.id;

        // Show success notification
        _ref.read(inAppNotificationServiceProvider.notifier).showRegistrationSuccess(
          result.user!.username,
        );
      } else {
        throw Exception(result.message ?? 'Registration failed');
      }
    } catch (e) {
      // Show error notification
      _ref.read(inAppNotificationServiceProvider.notifier).showError(
        'Registration Failed',
        _getRegistrationErrorMessage(e.toString()),
      );
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Call logout API
      await _authRepository.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      print('Logout API error: $e');
    }

    // Clear local storage
    await StorageService.clearAllData();

    // Clear ChatModel's currentUserId
    ChatModel.currentUserId = '';

    // Show logout notification
    _ref.read(inAppNotificationServiceProvider.notifier).showLogoutSuccess();

    // Update state
    state = const AuthState();
  }

  // Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    UserStatus? status,
    String? statusMessage,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        status: status?.value,
        statusMessage: statusMessage,
      );

      if (result.success && result.user != null) {
        // Save updated user data
        await StorageService.saveUserData(result.user!.toJson());

        // Update state
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception(result.message ?? 'Profile update failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Update avatar
  Future<void> updateAvatar(String avatarPath) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authRepository.updateAvatar(avatarPath);

      if (result.success && result.user != null) {
        // Save updated user data
        await StorageService.saveUserData(result.user!.toJson());

        // Update state
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          error: null,
        );
      } else {
        throw Exception(result.message ?? 'Avatar update failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Update user status
  Future<void> updateStatus(UserStatus status, {String? statusMessage}) async {
    if (state.user == null) return;

    try {
      final result = await _authRepository.updateProfile(
        status: status.value,
        statusMessage: statusMessage,
      );

      if (result.success && result.user != null) {
        // Save updated user data
        await StorageService.saveUserData(result.user!.toJson());

        // Update state
        state = state.copyWith(user: result.user);
      }
    } catch (e) {
      // Handle error silently for status updates
      print('Status update error: $e');
    }
  }

  // Update user status - alias for better API
  Future<void> updateUserStatus(
    UserStatus status,
    String? customMessage,
  ) async {
    await updateStatus(status, statusMessage: customMessage);
  }

  // Refresh token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return;
      }

      final result = await _authRepository.refreshToken(refreshToken);

      if (result.success && result.token != null) {
        await StorageService.saveAccessToken(result.token!);
        if (result.refreshToken != null) {
          await StorageService.saveRefreshToken(result.refreshToken!);
        }
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  // Get current user
  UserModel? get currentUser => state.user;

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // Helper method to format login error messages
  String _getLoginErrorMessage(String error) {
    final lowerError = error.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('socket')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else if (lowerError.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (lowerError.contains('invalid credentials') ||
        lowerError.contains('unauthorized') ||
        lowerError.contains('401') ||
        lowerError.contains('wrong password') ||
        lowerError.contains('incorrect password')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    } else if (lowerError.contains('user not found') ||
        lowerError.contains('404') ||
        lowerError.contains('account not found')) {
      return 'Account not found. Please check your email address or create a new account.';
    } else if (lowerError.contains('account locked') ||
        lowerError.contains('locked') ||
        lowerError.contains('suspended')) {
      return 'Your account is temporarily locked. Please contact support for assistance.';
    } else if (lowerError.contains('server') ||
        lowerError.contains('500') ||
        lowerError.contains('503') ||
        lowerError.contains('internal server error')) {
      return 'Server is temporarily unavailable. Please try again in a few minutes.';
    } else if (lowerError.contains('email not verified') ||
        lowerError.contains('verify email')) {
      return 'Please verify your email address before logging in. Check your inbox for verification link.';
    } else if (lowerError.contains('too many attempts') ||
        lowerError.contains('rate limit')) {
      return 'Too many login attempts. Please wait a few minutes before trying again.';
    } else if (lowerError.contains('maintenance')) {
      return 'System is under maintenance. Please try again later.';
    } else if (lowerError.contains('invalid email') ||
        lowerError.contains('email format')) {
      return 'Please enter a valid email address.';
    } else if (lowerError.contains('exception:')) {
      // Extract the actual error message after "Exception:"
      final parts = error.split('Exception:');
      if (parts.length > 1) {
        return parts[1].trim();
      }
      return 'Login failed. Please try again.';
    } else {
      return 'Login failed. Please check your credentials and try again.';
    }
  }

  // Helper method to format registration error messages
  String _getRegistrationErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('email already exists') || 
        lowerError.contains('email is already registered')) {
      return 'This email address is already registered. Please use a different email or try logging in.';
    }
    
    if (lowerError.contains('username already exists') || 
        lowerError.contains('username is taken')) {
      return 'This username is already taken. Please choose a different username.';
    }
    
    if (lowerError.contains('password') && 
        (lowerError.contains('weak') || lowerError.contains('requirements'))) {
      return 'Password is too weak. Please use at least 8 characters with a mix of letters, numbers, and symbols.';
    }

    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    
    if (lowerError.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    
    if (lowerError.contains('validation') || lowerError.contains('invalid')) {
      return 'Please check your information and try again.';
    }
    
    if (lowerError.contains('server') || lowerError.contains('unavailable')) {
      return 'Server error. Please try again later.';
    }

    if (lowerError.contains('exception:')) {
      // Extract the actual error message after "Exception:"
      final parts = error.split('Exception:');
      if (parts.length > 1) {
        return parts[1].trim();
      }
      return 'Registration failed. Please try again.';
    }

    return error;
  }
}

// Provider to check if app should redirect to login
final shouldRedirectToLoginProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return !authState.isAuthenticated && !authState.isLoading;
});

// Provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

// Provider for authentication loading state
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// Provider for authentication error
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
