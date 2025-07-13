import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/presence_model.dart';
import 'socket_service.dart';
import 'storage_service.dart';

class PresenceService {
  static PresenceService? _instance;
  static PresenceService get instance => _instance ??= PresenceService._();

  PresenceService._();

  // Current user presence
  UserPresence? _currentUserPresence;
  PresenceSettings _presenceSettings = const PresenceSettings();

  // Other users' presence
  final Map<String, UserPresence> _userPresences = {};

  // Stream controllers
  final _presenceStreamController =
      StreamController<Map<String, UserPresence>>.broadcast();
  final _currentUserPresenceStreamController =
      StreamController<UserPresence>.broadcast();
  final _presenceSettingsStreamController =
      StreamController<PresenceSettings>.broadcast();

  // Timers
  Timer? _idleTimer;
  Timer? _activityTimer;
  Timer? _heartbeatTimer;

  // Activity tracking
  bool _isIdle = false;
  DateTime _lastActivityTime = DateTime.now();
  String? _currentUserId;

  // Getters
  Stream<Map<String, UserPresence>> get presenceStream =>
      _presenceStreamController.stream;
  Stream<UserPresence> get currentUserPresenceStream =>
      _currentUserPresenceStreamController.stream;
  Stream<PresenceSettings> get presenceSettingsStream =>
      _presenceSettingsStreamController.stream;

  UserPresence? get currentUserPresence => _currentUserPresence;
  PresenceSettings get presenceSettings => _presenceSettings;
  Map<String, UserPresence> get userPresences =>
      Map.unmodifiable(_userPresences);

  // Initialize presence service
  Future<void> initialize(String userId) async {
    debugPrint('🟢 PresenceService: Initializing for user: $userId');

    _currentUserId = userId;

    // Load settings
    await _loadPresenceSettings();

    // Set up initial presence
    _currentUserPresence = UserPresence(
      userId: userId,
      state: PresenceState.online,
      lastSeen: DateTime.now(),
    );

    // Set up socket listeners
    _setupSocketListeners();

    // Start activity tracking
    _startActivityTracking();

    // Start heartbeat
    _startHeartbeat();

    // Send initial online status
    _sendPresenceUpdate('online');

    debugPrint('✅ PresenceService: Initialized successfully');
  }

  // Load presence settings from storage
  Future<void> _loadPresenceSettings() async {
    try {
      final settingsData = StorageService.getSetting('presence_settings');
      if (settingsData != null) {
        _presenceSettings = PresenceSettings.fromJson(settingsData);
        debugPrint(
          '📱 PresenceService: Loaded settings: ${_presenceSettings.toJson()}',
        );
      }
    } catch (e) {
      debugPrint('❌ PresenceService: Error loading settings: $e');
    }
  }

  // Save presence settings to storage
  Future<void> _savePresenceSettings() async {
    try {
      await StorageService.saveSetting(
        'presence_settings',
        _presenceSettings.toJson(),
      );
      debugPrint('💾 PresenceService: Settings saved');
    } catch (e) {
      debugPrint('❌ PresenceService: Error saving settings: $e');
    }
  }

  // Set up socket event listeners
  void _setupSocketListeners() {
    final socketService = SocketService.instance;

    // Listen for presence events
    socketService.userStatusStream.listen((data) {
      _handlePresenceEvent(data);
    });

    // Listen for connection changes
    socketService.connectionStream.listen((isConnected) {
      if (isConnected) {
        debugPrint(
          '🔗 PresenceService: Socket connected, sending online status',
        );
        _sendPresenceUpdate('online');
      } else {
        debugPrint('🔗 PresenceService: Socket disconnected');
        _handleDisconnection();
      }
    });
  }

  // Handle presence events from socket
  void _handlePresenceEvent(Map<String, dynamic> data) {
    try {
      final String type = data['type'];
      final String userId = data['userId'];

      debugPrint(
        '🔄 PresenceService: Received presence event: $type for user: $userId',
      );

      switch (type) {
        case 'online':
          _updateUserPresence(userId, PresenceState.online, data);
          break;
        case 'offline':
          _updateUserPresence(userId, PresenceState.offline, data);
          break;
        case 'away':
          _updateUserPresence(userId, PresenceState.away, data);
          break;
        case 'idle':
          _updateUserPresence(userId, PresenceState.idle, data);
          break;
        case 'statusChanged':
          _updateUserPresence(
            userId,
            PresenceState.fromString(data['status']),
            data,
          );
          break;
      }
    } catch (e) {
      debugPrint('❌ PresenceService: Error handling presence event: $e');
    }
  }

  // Update user presence
  void _updateUserPresence(
    String userId,
    PresenceState state,
    Map<String, dynamic> data,
  ) {
    final now = DateTime.now();
    final lastSeen = data['lastSeen'] != null
        ? DateTime.parse(data['lastSeen'])
        : now;

    final presence = UserPresence(
      userId: userId,
      state: state,
      lastSeen: state == PresenceState.online ? now : _lastActivityTime,
      customStatus: data['customStatus'],
    );

    _userPresences[userId] = presence;
    _presenceStreamController.add(Map.from(_userPresences));

    debugPrint(
      '📊 PresenceService: Updated presence for $userId: ${state.displayName}',
    );
  }

  // Start activity tracking
  void _startActivityTracking() {
    if (!_presenceSettings.enableIdleDetection) return;

    debugPrint('👁️ PresenceService: Starting activity tracking');

    // Set up idle timer
    _resetIdleTimer();

    // Set up activity timer to periodically check for activity
    _activityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkActivityStatus();
    });
  }

  // Reset idle timer
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _isIdle = false;
    _lastActivityTime = DateTime.now();

    if (!_presenceSettings.enableIdleDetection) return;

    _idleTimer = Timer(
      Duration(minutes: _presenceSettings.idleTimeoutMinutes),
      () {
        _setIdle();
      },
    );
  }

  // Set user as idle
  void _setIdle() {
    if (_isIdle || _presenceSettings.appearOffline) return;

    _isIdle = true;
    debugPrint('😴 PresenceService: User is now idle');

    _currentUserPresence = _currentUserPresence?.copyWith(
      state: PresenceState.idle,
      lastSeen: _lastActivityTime,
    );

    _currentUserPresenceStreamController.add(_currentUserPresence!);
    _sendPresenceUpdate(PresenceState.idle.value);
  }

  // Set user as active
  void _setActive() {
    if (!_isIdle) return;

    _isIdle = false;
    debugPrint('🏃 PresenceService: User is now active');

    _currentUserPresence = _currentUserPresence?.copyWith(
      state: PresenceState.online,
      lastSeen: DateTime.now(),
    );

    _currentUserPresenceStreamController.add(_currentUserPresence!);
    _sendPresenceUpdate('online');
    _resetIdleTimer();
  }

  // Check activity status
  void _checkActivityStatus() {
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivityTime);

    if (timeSinceLastActivity.inMinutes >=
        _presenceSettings.idleTimeoutMinutes) {
      if (!_isIdle) {
        _setIdle();
      }
    }
  }

  // Track user activity
  void trackActivity() {
    if (_presenceSettings.appearOffline) return;

    _lastActivityTime = DateTime.now();

    if (_isIdle) {
      _setActive();
    } else {
      _resetIdleTimer();
    }
  }

  // Start heartbeat to maintain connection
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_currentUserPresence != null && !_presenceSettings.appearOffline) {
        _sendPresenceUpdate(_currentUserPresence!.state.value);
      }
    });
  }

  // Send presence update to server
  void _sendPresenceUpdate(String status) {
    if (_presenceSettings.appearOffline && status != 'offline') {
      return; // Don't send online/away updates if user wants to appear offline
    }

    final socketService = SocketService.instance;
    if (!socketService.isConnected) return;

    socketService.updateUserStatus(status);
    debugPrint('📡 PresenceService: Sent presence update: $status');
  }

  // Handle disconnection
  void _handleDisconnection() {
    debugPrint('🔌 PresenceService: Handling disconnection');

    _currentUserPresence = _currentUserPresence?.copyWith(
      state: PresenceState.offline,
      lastSeen: DateTime.now(),
    );

    if (_currentUserPresence != null) {
      _currentUserPresenceStreamController.add(_currentUserPresence!);
    }
  }

  // Update presence settings
  Future<void> updatePresenceSettings(PresenceSettings newSettings) async {
    final oldSettings = _presenceSettings;
    _presenceSettings = newSettings;

    await _savePresenceSettings();
    _presenceSettingsStreamController.add(_presenceSettings);

    // Handle setting changes
    if (oldSettings.enableIdleDetection != newSettings.enableIdleDetection) {
      if (newSettings.enableIdleDetection) {
        _startActivityTracking();
      } else {
        _idleTimer?.cancel();
        _activityTimer?.cancel();
        if (_isIdle) {
          _setActive();
        }
      }
    }

    if (oldSettings.appearOffline != newSettings.appearOffline) {
      if (newSettings.appearOffline) {
        _sendPresenceUpdate(PresenceState.offline.value);
      } else {
        _sendPresenceUpdate(PresenceState.online.value);
      }
    }

    debugPrint('⚙️ PresenceService: Settings updated: ${newSettings.toJson()}');
  }

  // Manually set user status
  Future<void> setUserStatus(
    PresenceState state, {
    String? customStatus,
  }) async {
    _currentUserPresence = _currentUserPresence?.copyWith(
      state: state,
      customStatus: customStatus,
      lastSeen: DateTime.now(),
    );

    if (_currentUserPresence != null) {
      _currentUserPresenceStreamController.add(_currentUserPresence!);
    }

    _sendPresenceUpdate(state.value);
    debugPrint(
      '👤 PresenceService: Manual status update: ${state.displayName}',
    );
  }

  // Get user presence
  UserPresence? getUserPresence(String userId) {
    return _userPresences[userId];
  }

  // Get users by presence state
  List<UserPresence> getUsersByState(PresenceState state) {
    return _userPresences.values.where((p) => p.state == state).toList();
  }

  // Dispose resources
  void dispose() {
    debugPrint('🔄 PresenceService: Disposing resources');

    _idleTimer?.cancel();
    _activityTimer?.cancel();
    _heartbeatTimer?.cancel();

    _presenceStreamController.close();
    _currentUserPresenceStreamController.close();
    _presenceSettingsStreamController.close();

    _userPresences.clear();
    _currentUserPresence = null;
  }
}
