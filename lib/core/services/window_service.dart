import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static const String _appTitle = 'ADRDE Professional Chat';
  static const Size _minSize = Size(1000, 700);
  static const Size _defaultSize = Size(1200, 800);

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized ||
        !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    try {
      // Must add this line for window_manager to work
      await windowManager.ensureInitialized();

      // Configure window options
      const windowOptions = WindowOptions(
        size: _defaultSize,
        minimumSize: _minSize,
        center: true,
        backgroundColor: Color(0xFF1E1E1E),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        windowButtonVisibility: true,
        title: _appTitle,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setTitle(_appTitle);
      });

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Window initialization error: $e');
      }
    }
  }

  static Future<void> setTitle(String title) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setTitle('$title - $_appTitle');
    } catch (e) {
      if (kDebugMode) {
        print('Set title error: $e');
      }
    }
  }

  static Future<void> resetTitle() async {
    if (!_isInitialized) return;

    try {
      await windowManager.setTitle(_appTitle);
    } catch (e) {
      if (kDebugMode) {
        print('Reset title error: $e');
      }
    }
  }

  static Future<void> minimize() async {
    if (!_isInitialized) return;

    try {
      await windowManager.minimize();
    } catch (e) {
      if (kDebugMode) {
        print('Minimize error: $e');
      }
    }
  }

  static Future<void> maximize() async {
    if (!_isInitialized) return;

    try {
      await windowManager.maximize();
    } catch (e) {
      if (kDebugMode) {
        print('Maximize error: $e');
      }
    }
  }

  static Future<void> unmaximize() async {
    if (!_isInitialized) return;

    try {
      await windowManager.unmaximize();
    } catch (e) {
      if (kDebugMode) {
        print('Unmaximize error: $e');
      }
    }
  }

  static Future<bool> isMaximized() async {
    if (!_isInitialized) return false;

    try {
      return await windowManager.isMaximized();
    } catch (e) {
      if (kDebugMode) {
        print('Is maximized error: $e');
      }
      return false;
    }
  }

  static Future<void> center() async {
    if (!_isInitialized) return;

    try {
      await windowManager.center();
    } catch (e) {
      if (kDebugMode) {
        print('Center error: $e');
      }
    }
  }

  static Future<void> hide() async {
    if (!_isInitialized) return;

    try {
      await windowManager.hide();
    } catch (e) {
      if (kDebugMode) {
        print('Hide error: $e');
      }
    }
  }

  static Future<void> show() async {
    if (!_isInitialized) return;

    try {
      await windowManager.show();
    } catch (e) {
      if (kDebugMode) {
        print('Show error: $e');
      }
    }
  }

  static Future<void> focus() async {
    if (!_isInitialized) return;

    try {
      await windowManager.focus();
    } catch (e) {
      if (kDebugMode) {
        print('Focus error: $e');
      }
    }
  }

  static Future<void> setSize(Size size) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setSize(size);
    } catch (e) {
      if (kDebugMode) {
        print('Set size error: $e');
      }
    }
  }

  static Future<Size> getSize() async {
    if (!_isInitialized) return _defaultSize;

    try {
      return await windowManager.getSize();
    } catch (e) {
      if (kDebugMode) {
        print('Get size error: $e');
      }
      return _defaultSize;
    }
  }

  static Future<void> setPosition(Offset position) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setPosition(position);
    } catch (e) {
      if (kDebugMode) {
        print('Set position error: $e');
      }
    }
  }

  static Future<Offset> getPosition() async {
    if (!_isInitialized) return Offset.zero;

    try {
      return await windowManager.getPosition();
    } catch (e) {
      if (kDebugMode) {
        print('Get position error: $e');
      }
      return Offset.zero;
    }
  }

  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    } catch (e) {
      if (kDebugMode) {
        print('Set always on top error: $e');
      }
    }
  }

  static Future<void> setFullScreen(bool fullScreen) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setFullScreen(fullScreen);
    } catch (e) {
      if (kDebugMode) {
        print('Set full screen error: $e');
      }
    }
  }

  static Future<bool> isFullScreen() async {
    if (!_isInitialized) return false;

    try {
      return await windowManager.isFullScreen();
    } catch (e) {
      if (kDebugMode) {
        print('Is full screen error: $e');
      }
      return false;
    }
  }

  static Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await windowManager.close();
    } catch (e) {
      if (kDebugMode) {
        print('Close error: $e');
      }
    }
  }

  // Keyboard shortcuts
  static Future<void> setupKeyboardShortcuts() async {
    if (!_isInitialized) return;

    // Setup global keyboard shortcuts
    try {
      // Ctrl+Q to quit
      RawKeyboard.instance.addListener((RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          final isCtrlPressed = event.isControlPressed;
          final isMetaPressed = event.isMetaPressed; // For macOS

          // Quit shortcut
          if ((isCtrlPressed || isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.keyQ) {
            close();
          }

          // Minimize shortcut
          if ((isCtrlPressed || isMetaPressed) &&
              event.logicalKey == LogicalKeyboardKey.keyM) {
            minimize();
          }

          // Toggle fullscreen
          if (event.logicalKey == LogicalKeyboardKey.f11) {
            toggleFullScreen();
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Setup keyboard shortcuts error: $e');
      }
    }
  }

  static Future<void> toggleFullScreen() async {
    if (!_isInitialized) return;

    try {
      final isFullScreen = await WindowService.isFullScreen();
      await WindowService.setFullScreen(!isFullScreen);
    } catch (e) {
      if (kDebugMode) {
        print('Toggle full screen error: $e');
      }
    }
  }

  static Future<void> toggleMaximize() async {
    if (!_isInitialized) return;

    try {
      final isMaximized = await WindowService.isMaximized();
      if (isMaximized) {
        await WindowService.unmaximize();
      } else {
        await WindowService.maximize();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Toggle maximize error: $e');
      }
    }
  }

  // Save and restore window state
  static Future<void> saveWindowState() async {
    if (!_isInitialized) return;

    try {
      final size = await getSize();
      final position = await getPosition();
      final isMaximized = await WindowService.isMaximized();

      // Save to preferences (you can use SharedPreferences or Hive)
      // This is a placeholder - implement according to your storage solution
      await _saveWindowPreferences({
        'width': size.width,
        'height': size.height,
        'x': position.dx,
        'y': position.dy,
        'isMaximized': isMaximized,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Save window state error: $e');
      }
    }
  }

  static Future<void> restoreWindowState() async {
    if (!_isInitialized) return;

    try {
      final preferences = await _loadWindowPreferences();
      if (preferences != null) {
        if (preferences['isMaximized'] == true) {
          await maximize();
        } else {
          await setSize(
            Size(
              preferences['width'] ?? _defaultSize.width,
              preferences['height'] ?? _defaultSize.height,
            ),
          );
          await setPosition(
            Offset(preferences['x'] ?? 0, preferences['y'] ?? 0),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Restore window state error: $e');
      }
    }
  }

  // Placeholder methods for window preferences
  // Replace with your actual storage implementation
  static Future<void> _saveWindowPreferences(
    Map<String, dynamic> preferences,
  ) async {
    // TODO: Implement with SharedPreferences or Hive
  }

  static Future<Map<String, dynamic>?> _loadWindowPreferences() async {
    // TODO: Implement with SharedPreferences or Hive
    return null;
  }

  // Helper methods
  static bool get isDesktop {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool get isInitialized => _isInitialized;

  // Window event handlers
  static void onWindowClose() {
    saveWindowState();
  }

  static void onWindowResize() {
    // Handle window resize events
  }

  static void onWindowMove() {
    // Handle window move events
  }
}
