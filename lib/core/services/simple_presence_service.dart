import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/presence_model.dart';
import 'socket_service.dart';
import 'storage_service.dart';

class SimplePresenceService {
  static SimplePresenceService? _instance;
  static SimplePresenceService get instance =>
      _instance ??= SimplePresenceService._();

  SimplePresenceService._();

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

  // Timers
  Timer? _idleTimer;
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

  UserPresence? get currentUserPresence => _currentUserPresence;
  PresenceSettings get presenceSettings => _presenceSettings;
  Map<String, UserPresence> get userPresences =>
      Map.unmodifiable(_userPresences);

  // Initialize presence service
  Future<void> initialize(String userId) async {
    debugPrint('🟢 SimplePresenceService: Initializing for user: $userId');

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

    debugPrint('✅ SimplePresenceService: Initialized successfully');
  }

  // Load presence settings from storage
  Future<void> _loadPresenceSettings() async {
    try {
      final settingsData = StorageService.getSetting<Map<String, dynamic>>(
        'presence_settings',
      );
      if (settingsData != null) {
        _presenceSettings = PresenceSettings.fromJson(settingsData);
        debugPrint(
          '📱 SimplePresenceService: Loaded settings: ${_presenceSettings.toJson()}',
        );
      }
    } catch (e) {
      debugPrint('❌ SimplePresenceService: Error loading settings: $e');
    }
  }

  // Save presence settings to storage
  Future<void> _savePresenceSettings() async {
    try {
      await StorageService.saveSetting(
        'presence_settings',
        _presenceSettings.toJson(),
      );
      debugPrint('💾 SimplePresenceService: Settings saved');
    } catch (e) {
      debugPrint('❌ SimplePresenceService: Error saving settings: $e');
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
          '🔗 SimplePresenceService: Socket connected, sending online status',
        );
        _sendPresenceUpdate('online');
      } else {
        debugPrint('🔗 SimplePresenceService: Socket disconnected');
        _handleDisconnection();
      }
    });
  }

  // Handle presence events from socket
  void _handlePresenceEvent(Map<String, dynamic> data) {
    try {
      final String type = data['type'];
      final String userId = data['userId'];

      if (userId == _currentUserId) return; // Don't update our own presence

      debugPrint(
        '🔄 SimplePresenceService: Received presence event: $type for user: $userId',
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
        case 'statusChanged':
          final status = data['status'];
          if (status == 'online') {
            _updateUserPresence(userId, PresenceState.online, data);
          } else if (status == 'away') {
            _updateUserPresence(userId, PresenceState.away, data);
          } else {
            _updateUserPresence(userId, PresenceState.offline, data);
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ SimplePresenceService: Error handling presence event: $e');
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
        ? DateTime.tryParse(data['lastSeen']) ?? now
        : now;

    final presence = UserPresence(
      userId: userId,
      state: state,
      lastSeen: lastSeen,
      customStatus: data['customStatus'],
    );

    _userPresences[userId] = presence;
    _presenceStreamController.add(Map.from(_userPresences));

    debugPrint(
      '📊 SimplePresenceService: Updated presence for $userId: ${state.displayName}',
    );
  }

  // Start activity tracking
  void _startActivityTracking() {
    if (!_presenceSettings.enableIdleDetection) return;

    debugPrint('👁️ SimplePresenceService: Starting activity tracking');

    // Set up idle timer
    _resetIdleTimer();
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
    debugPrint('😴 SimplePresenceService: User is now idle');

    _currentUserPresence = _currentUserPresence?.copyWith(
      state: PresenceState.away,
      lastSeen: _lastActivityTime,
    );

    if (_currentUserPresence != null) {
      _currentUserPresenceStreamController.add(_currentUserPresence!);
    }
    _sendPresenceUpdate('away');
  }

  // Set user as active
  void _setActive() {
    if (!_isIdle) return;

    _isIdle = false;
    debugPrint('🏃 SimplePresenceService: User is now active');

    _currentUserPresence = _currentUserPresence?.copyWith(
      state: PresenceState.online,
      lastSeen: DateTime.now(),
    );

    if (_currentUserPresence != null) {
      _currentUserPresenceStreamController.add(_currentUserPresence!);
    }
    _sendPresenceUpdate('online');
    _resetIdleTimer();
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
    debugPrint('📡 SimplePresenceService: Sent presence update: $status');
  }

  // Handle disconnection
  void _handleDisconnection() {
    debugPrint('🔌 SimplePresenceService: Handling disconnection');

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

    // Handle setting changes
    if (oldSettings.enableIdleDetection != newSettings.enableIdleDetection) {
      if (newSettings.enableIdleDetection) {
        _startActivityTracking();
      } else {
        _idleTimer?.cancel();
        if (_isIdle) {
          _setActive();
        }
      }
    }

    if (oldSettings.appearOffline != newSettings.appearOffline) {
      if (newSettings.appearOffline) {
        _sendPresenceUpdate('offline');
      } else {
        _sendPresenceUpdate('online');
      }
    }

    debugPrint(
      '⚙️ SimplePresenceService: Settings updated: ${newSettings.toJson()}',
    );
  }

  // Manually set user status
  Future<void> setUserStatus(PresenceState state) async {
    _currentUserPresence = _currentUserPresence?.copyWith(
      state: state,
      lastSeen: DateTime.now(),
    );

    if (_currentUserPresence != null) {
      _currentUserPresenceStreamController.add(_currentUserPresence!);
    }

    _sendPresenceUpdate(state.value);
    debugPrint(
      '👤 SimplePresenceService: Manual status update: ${state.displayName}',
    );
  }

  // Get user presence
  UserPresence? getUserPresence(String userId) {
    return _userPresences[userId];
  }

  // Dispose resources
  void dispose() {
    debugPrint('🔄 SimplePresenceService: Disposing resources');

    _idleTimer?.cancel();
    _heartbeatTimer?.cancel();

    _presenceStreamController.close();
    _currentUserPresenceStreamController.close();

    _userPresences.clear();
    _currentUserPresence = null;
  }
}
