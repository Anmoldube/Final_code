import '../../../../core/models/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? token;
  final String? refreshToken;
  final bool isOfflineLogin;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.isOfflineLogin = false,
  });

  factory AuthResult.success({
    UserModel? user,
    String? token,
    String? refreshToken,
    String? message,
    bool isOfflineLogin = false,
  }) {
    return AuthResult(
      success: true,
      user: user,
      token: token,
      refreshToken: refreshToken,
      message: message,
      isOfflineLogin: isOfflineLogin,
    );
  }

  factory AuthResult.failure({required String message}) {
    return AuthResult(success: false, message: message);
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, user: $user, hasToken: ${token != null}, isOfflineLogin: $isOfflineLogin)';
  }
}
