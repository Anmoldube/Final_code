import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/enhanced_auth_service.dart';
import 'core/services/notification_service_simple.dart';
import 'core/services/window_service.dart';
import 'core/services/app_initialization_service.dart';
import 'core/services/app_startup_service.dart';
import 'core/services/socket_event_handler.dart';
import 'core/services/file_service.dart';
import 'core/services/offline_service.dart';
import 'core/widgets/activity_tracker.dart';
import 'core/services/in_app_notification_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/chat/presentation/providers/message_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize storage service
  await StorageService.initialize();

  // Initialize enhanced auth service
  EnhancedAuthService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize theme
  AppTheme.initialize();

  // Initialize path_provider and ensure download directories exist
  try {
    // Ensure application documents directory exists
    final appDocDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDocDir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    debugPrint('✅ Downloads directory initialized: ${downloadsDir.path}');

    // Also initialize temporary directory as fallback
    final tempDir = await getTemporaryDirectory();
    debugPrint('✅ Temporary directory available: ${tempDir.path}');
  } catch (e) {
    debugPrint('⚠️ Error initializing file directories: $e');
    // Continue app initialization even if this fails
  }

  // Initialize offline service
  await OfflineService().initialize();

  // Run startup validations (including timestamp checks)
  await AppStartupService.runStartupValidations();

  // Initialize app with backend connection
  debugPrint('🚀 Starting Flutter app with Node.js backend connection...');
  final initSuccess = await AppInitializationService.initialize();

  if (initSuccess) {
    debugPrint('✅ Backend connection established successfully');
  } else {
    debugPrint('⚠️ Backend connection failed, app will run in offline mode');
    // Try to sync offline data when connection is restored
    OfflineService().connectivityStream.listen((isOnline) {
      if (isOnline) {
        debugPrint(
          '🔄 Connection restored, attempting to sync offline data...',
        );
        OfflineService().syncOfflineData();
      }
    });
  }

  // Initialize file service early
  FileService.instance.initialize();

  runApp(const ProviderScope(child: ADRDEChatApp()));
}

class ADRDEChatApp extends ConsumerStatefulWidget {
  const ADRDEChatApp({super.key});

  @override
  ConsumerState<ADRDEChatApp> createState() => _ADRDEChatAppState();
}

class _ADRDEChatAppState extends ConsumerState<ADRDEChatApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
      // Initialize socket event handler
      SocketEventHandler.instance.initialize(ref);
      // File service is already initialized in main()
      // Initialize message status provider to ensure socket listeners are set up
      ref.read(messageStatusProvider.notifier);
    });
  }

  @override
  void dispose() {
    // Dispose socket event handler
    SocketEventHandler.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'ADRDE Professional Chat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, child) {
            // Handle system keyboard shortcuts
            return Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.keyQ,
                ): const ExitIntent(),
                LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(),
                LogicalKeySet(
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.keyN,
                ): const NewChatIntent(),
                LogicalKeySet(
                  LogicalKeyboardKey.control,
                  LogicalKeyboardKey.keyF,
                ): const SearchIntent(),
                LogicalKeySet(LogicalKeyboardKey.f11): const FullScreenIntent(),
              },
              child: Actions(
                actions: <Type, Action<Intent>>{
                  ExitIntent: CallbackAction<ExitIntent>(
                    onInvoke: (ExitIntent intent) async {
                      await WindowService.close();
                      return null;
                    },
                  ),
                  EscapeIntent: CallbackAction<EscapeIntent>(
                    onInvoke: (EscapeIntent intent) {
                      Navigator.of(context).maybePop();
                      return null;
                    },
                  ),
                  NewChatIntent: CallbackAction<NewChatIntent>(
                    onInvoke: (NewChatIntent intent) {
                      // Handle new chat shortcut
                      return null;
                    },
                  ),
                  SearchIntent: CallbackAction<SearchIntent>(
                    onInvoke: (SearchIntent intent) {
                      // Handle search shortcut
                      return null;
                    },
                  ),
                  FullScreenIntent: CallbackAction<FullScreenIntent>(
                    onInvoke: (FullScreenIntent intent) async {
                      await WindowService.toggleFullScreen();
                      return null;
                    },
                  ),
                },
                child: ActivityTracker(
                  child: InAppNotificationOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Custom intents for keyboard shortcuts
class ExitIntent extends Intent {
  const ExitIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class NewChatIntent extends Intent {
  const NewChatIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class FullScreenIntent extends Intent {
  const FullScreenIntent();
}
