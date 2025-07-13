import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/login_success_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../pages/connection_test_page.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state to trigger router rebuilds
  ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login-success',
        name: 'login-success',
        builder: (context, state) => const LoginSuccessScreen(),
      ),

      // Connection Test Route (for development/testing)
      GoRoute(
        path: '/connection-test',
        name: 'connection-test',
        builder: (context, state) => const ConnectionTestPage(),
      ),

      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Chat Screen
          GoRoute(
            path: 'chat/:chatId',
            name: 'chat',
            builder: (context, state) {
              final chatId = state.pathParameters['chatId']!;
              final chatName = state.uri.queryParameters['name'] ?? 'Chat';
              final isGroup = state.uri.queryParameters['isGroup'] == 'true';
              final avatarUrl = state.uri.queryParameters['avatarUrl'];

              return ChatScreen(
                chatId: chatId,
                chatName: chatName,
                isGroup: isGroup,
                avatarUrl: avatarUrl,
              );
            },
          ),

          // Profile Screen
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Settings Screen
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],

    // Redirect logic - simplified to avoid infinite loops
    redirect: (context, state) async {
      try {
        final authState = ref.read(authProvider);
        final isLoggedIn = authState.isAuthenticated;
        final isLoading = authState.isLoading;
        final currentLocation = state.matchedLocation;

        print(
          '🔄 Router redirect: location=$currentLocation, isLoggedIn=$isLoggedIn, isLoading=$isLoading',
        );

        // Don't redirect while auth is loading
        if (isLoading) {
          print('⏳ Router: Auth loading, staying on current page');
          return null;
        }

        // If on splash screen, let it handle the navigation
        if (currentLocation == '/splash') {
          print('🚀 Router: Staying on splash screen');
          return null;
        }

        // If user is logged in but on auth pages, redirect to home
        if (isLoggedIn &&
            (currentLocation == '/login' ||
                currentLocation == '/register' ||
                currentLocation == '/login-success')) {
          print('🏠 Router: User logged in, redirecting to home');
          return '/home';
        }

        // If user is not logged in and trying to access protected routes
        if (!isLoggedIn &&
            currentLocation != '/login' &&
            currentLocation != '/register' &&
            currentLocation != '/connection-test') {
          print('🔐 Router: User not logged in, redirecting to login');
          return '/login';
        }

        print('✅ Router: No redirect needed');
        return null;
      } catch (e, stackTrace) {
        print('❌ Router redirect error: $e');
        print('Stack trace: $stackTrace');
        return '/login'; // Fallback to login on error
      }
    },

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.matchedLocation}" could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation extension for easy navigation
extension AppRouterExtension on GoRouter {
  void pushChat({
    required String chatId,
    required String chatName,
    bool isGroup = false,
    String? avatarUrl,
  }) {
    pushNamed(
      'chat',
      pathParameters: {'chatId': chatId},
      queryParameters: {
        'name': chatName,
        'isGroup': isGroup.toString(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
  }
}

// Helper class for route information
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/home/chat';
  static const String profile = '/home/profile';
  static const String settings = '/home/settings';

  // Route names
  static const String splashName = 'splash';
  static const String loginName = 'login';
  static const String registerName = 'register';
  static const String homeName = 'home';
  static const String chatName = 'chat';
  static const String profileName = 'profile';
  static const String settingsName = 'settings';
}
