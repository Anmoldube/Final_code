import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/in_app_notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/auth_state.dart';

import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoggingIn = false;
  DateTime? _lastLoginAttempt;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedCredentials();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  void _loadSavedCredentials() {
    // Load saved credentials if remember me was checked
    // This will be implemented with the storage service
  }

  void _onFieldChanged() {
    // Clear messages when user starts typing
    if (_errorMessage != null || _successMessage != null) {
      _clearMessages();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLoggingIn) return;

    // Prevent rapid successive login attempts
    final now = DateTime.now();
    if (_lastLoginAttempt != null &&
        now.difference(_lastLoginAttempt!) < const Duration(seconds: 2)) {
      ref.read(inAppNotificationServiceProvider.notifier).showError(
        'Too Many Attempts',
        'Please wait a moment before trying again',
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _lastLoginAttempt = now;
    });

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      
      if (!mounted) return;

      final authState = ref.read(authProvider);
      
      if (authState.isAuthenticated && authState.user != null) {
        if (_rememberMe) {
          await StorageService.saveCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );
        }
        
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _saveLoginCredentials() async {
    try {
      await StorageService.saveCredentials(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });

    // Auto-hide error message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
  }

  String _getErrorMessage(String error) {
    // Convert technical error messages to user-friendly ones
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

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to auth state changes for error handling
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showErrorMessage(_getErrorMessage(next.error!));
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo and Welcome
                              _buildHeader(),

                              const SizedBox(height: 32),

                              // Error/Success Messages
                              _buildMessageDisplay(),

                              const SizedBox(height: 16),

                              // Email Field
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Enter your email address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: (_) => _onFieldChanged(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!EmailValidator.validate(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Password Field
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline,
                                obscureText: !_isPasswordVisible,
                                onChanged: (_) => _onFieldChanged(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // Remember Me & Forgot Password
                              _buildOptionsRow(),

                              const SizedBox(height: 32),

                              // Login Button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoggingIn ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoggingIn
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.7,
                                          )
                                        : AppTheme.primaryColor,
                                  ),
                                  child: _isLoggingIn
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Signing In...',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        )
                                      : const Text('Sign In'),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'Or continue with',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Social Login Buttons (if needed)
                              // _buildSocialButtons(),

                              // const SizedBox(height: 32),

                              // Sign Up Link
                              _buildSignUpLink(),

                              // Debug Connection Test Button (only in debug mode)
                              if (kDebugMode) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () =>
                                      context.push('/connection-test'),
                                  icon: const Icon(Icons.network_check),
                                  label: const Text(' '),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.orange,
                                  ),
                                ),
                              ],
                            ],
                          ), // End Column
                        ), // End Form
                      ), // End ConstrainedBox
                    ), // End SingleChildScrollView
                  ), // End Center
                ), // End SlideTransition
              ); // End FadeTransition
            }, // End builder
          ), // End AnimatedBuilder
        ), // End GestureDetector
      ), // End SafeArea
    ); // End Scaffold
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 24),

        // Welcome Text
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Sign in to your ADRDE Chat account',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessageDisplay() {
    if (_errorMessage == null && _successMessage == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorMessage != null
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _errorMessage != null
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : AppTheme.successColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _errorMessage != null
                ? Icons.error_outline
                : Icons.check_circle_outline,
            color: _errorMessage != null
                ? AppTheme.errorColor
                : AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? _successMessage ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _errorMessage != null
                    ? AppTheme.errorColor
                    : AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_errorMessage != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: Icon(Icons.close, color: AppTheme.errorColor, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Remember Me
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember me',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Forgot Password
        TextButton(
          onPressed: _handleForgotPassword,
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text(
          'Please contact your system administrator to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
