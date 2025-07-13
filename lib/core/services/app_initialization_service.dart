import 'package:flutter/foundation.dart';
import 'connection_test_service.dart';
import 'storage_service.dart';
import 'socket_service.dart';
import 'simple_presence_service.dart';
import 'enhanced_file_service.dart';
import 'file_service.dart';

class AppInitializationService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Initialize the app with backend connection
  static Future<bool> initialize() async {
    if (_isInitialized) {
      debugPrint('App already initialized');
      return true;
    }

    debugPrint('🚀 Initializing app...');

    try {
      // Step 1: Initialize storage service
      debugPrint('📱 Initializing storage service...');
      await StorageService.initialize();
      debugPrint('✅ Storage service initialized');

      // Step 1.5: Initialize file services
      debugPrint('📁 Initializing file services...');
      FileService.instance.initialize();
      EnhancedFileService.instance.initialize();
      debugPrint('✅ File services initialized');

      // Step 2:  
      debugPrint('🌐 Testing backend connection...');
      final connectionSuccess = await ConnectionTestService.testConnection();

      if (!connectionSuccess) {
        debugPrint('❌ Backend connection failed');
        return false;
      }

      // Step 3: Test auth endpoints
      debugPrint('🔐 Testing authentication endpoints...');
      final authResults = await ConnectionTestService.testAuthEndpoints();
      final authWorking = authResults.values.any((result) => result == true);

      if (!authWorking) {
        debugPrint('❌ Authentication endpoints not working');
        return false;
      }

      // Step 4: Check if user is already logged in
      final token = await StorageService.getAccessToken();
      if (token != null) {
        debugPrint(
          '🔑 Found existing token, testing authenticated endpoints...',
        );

        // Test authenticated endpoints
        final chatResults = await ConnectionTestService.testChatEndpoints(
          token,
        );
        final messageResults = await ConnectionTestService.testMessageEndpoints(
          token,
        );

        final authenticatedEndpointsWorking =
            chatResults.values.any((result) => result == true) ||
            messageResults.values.any((result) => result == true);

        if (authenticatedEndpointsWorking) {
          debugPrint('✅ Authenticated endpoints working');

          // Initialize socket connection
          final userId = StorageService.getUserId();
          if (userId != null) {
            debugPrint('🔌 Initializing socket connection...');
            await SocketService.instance.connect(userId);
            debugPrint('✅ Socket connection initialized');

            // Initialize presence service
            if (SocketService.instance.isConnected) {
              debugPrint('🟢 Initializing presence service...');
              await SimplePresenceService.instance.initialize(userId);
              debugPrint('✅ Presence service initialized');
            }
          }
        } else {
          debugPrint('⚠️ Authenticated endpoints not working, clearing tokens');
          await StorageService.clearTokens();
        }
      }

      _isInitialized = true;
      debugPrint('🎉 App initialization completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      return false;
    }
  }

  /// Get initialization status and backend info
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'backendInfo': ConnectionTestService.getBackendInfo(),
      'socketConnected': SocketService.instance.isConnected,
    };
  }

  /// Reinitialize the app (useful for reconnection)
  static Future<bool> reinitialize() async {
    debugPrint('🔄 Reinitializing app...');
    _isInitialized = false;

    // Disconnect socket if connected
    if (SocketService.instance.isConnected) {
      await SocketService.instance.disconnect();
    }

    return await initialize();
  }

  /// Clean shutdown
  static Future<void> shutdown() async {
    debugPrint('🛑 Shutting down app services...');

    // Disconnect socket
    if (SocketService.instance.isConnected) {
      await SocketService.instance.disconnect();
    }

    _isInitialized = false;
    debugPrint('✅ App services shut down');
  }
}
