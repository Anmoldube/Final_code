import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/presence_model.dart' as presence_model;
import '../services/presence_service.dart';

// Presence provider state class
class PresenceProviderState {
  final Map<String, presence_model.UserPresence> userPresences;
  final presence_model.UserPresence? currentUserPresence;
  final presence_model.PresenceSettings presenceSettings;
  final bool isLoading;
  final String? error;

  const PresenceProviderState({
    this.userPresences = const {},
    this.currentUserPresence,
    this.presenceSettings = const presence_model.PresenceSettings(),
    this.isLoading = false,
    this.error,
  });

  PresenceProviderState copyWith({
    Map<String, presence_model.UserPresence>? userPresences,
    presence_model.UserPresence? currentUserPresence,
    presence_model.PresenceSettings? presenceSettings,
    bool? isLoading,
    String? error,
  }) {
    return PresenceProviderState(
      userPresences: userPresences ?? this.userPresences,
      currentUserPresence: currentUserPresence ?? this.currentUserPresence,
      presenceSettings: presenceSettings ?? this.presenceSettings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Presence notifier
class PresenceNotifier extends StateNotifier<PresenceProviderState> {
  final PresenceService _presenceService;

  PresenceNotifier(this._presenceService)
    : super(const PresenceProviderState()) {
    _initialize();
  }

  void _initialize() {
    // Listen to presence streams
    _presenceService.presenceStream.listen((userPresences) {
      state = state.copyWith(userPresences: userPresences, error: null);
    });

    _presenceService.currentUserPresenceStream.listen((currentUserPresence) {
      state = state.copyWith(
        currentUserPresence: currentUserPresence,
        error: null,
      );
    });

    _presenceService.presenceSettingsStream.listen((presenceSettings) {
      state = state.copyWith(presenceSettings: presenceSettings, error: null);
    });
  }

  // Initialize presence for a user
  Future<void> initializePresence(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _presenceService.initialize(userId);
      state = state.copyWith(
        isLoading: false,
        currentUserPresence: _presenceService.currentUserPresence,
        presenceSettings: _presenceService.presenceSettings,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('❌ PresenceProvider: Error initializing presence: $e');
    }
  }

  // Update presence settings
  Future<void> updatePresenceSettings(
    presence_model.PresenceSettings settings,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _presenceService.updatePresenceSettings(settings);
      state = state.copyWith(isLoading: false, presenceSettings: settings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('❌ PresenceProvider: Error updating settings: $e');
    }
  }

  // Set user status
  Future<void> setUserStatus(
    presence_model.PresenceState presenceState, {
    String? customStatus,
  }) async {
    try {
      await _presenceService.setUserStatus(
        presenceState,
        customStatus: customStatus,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('❌ PresenceProvider: Error setting user status: $e');
    }
  }

  // Track user activity
  void trackActivity() {
    _presenceService.trackActivity();
  }

  // Get user presence
  presence_model.UserPresence? getUserPresence(String userId) {
    return state.userPresences[userId];
  }

  // Get online users
  List<presence_model.UserPresence> getOnlineUsers() {
    return state.userPresences.values
        .where((presence) => presence.isOnline)
        .toList();
  }

  // Get away users
  List<presence_model.UserPresence> getAwayUsers() {
    return state.userPresences.values
        .where((presence) => presence.isAway)
        .toList();
  }

  // Get offline users
  List<presence_model.UserPresence> getOfflineUsers() {
    return state.userPresences.values
        .where((presence) => presence.isOffline)
        .toList();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _presenceService.dispose();
    super.dispose();
  }
}

// Providers
final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService.instance;
});

final presenceProvider =
    StateNotifierProvider<PresenceNotifier, PresenceProviderState>((ref) {
      final presenceService = ref.watch(presenceServiceProvider);
      return PresenceNotifier(presenceService);
    });

// Computed providers
final currentUserPresenceProvider = Provider<presence_model.UserPresence?>((
  ref,
) {
  return ref.watch(presenceProvider).currentUserPresence;
});

final presenceSettingsProvider = Provider<presence_model.PresenceSettings>((
  ref,
) {
  return ref.watch(presenceProvider).presenceSettings;
});

final userPresencesProvider =
    Provider<Map<String, presence_model.UserPresence>>((ref) {
      return ref.watch(presenceProvider).userPresences;
    });

final onlineUsersProvider = Provider<List<presence_model.UserPresence>>((ref) {
  return ref.watch(presenceProvider.notifier).getOnlineUsers();
});

final awayUsersProvider = Provider<List<presence_model.UserPresence>>((ref) {
  return ref.watch(presenceProvider.notifier).getAwayUsers();
});

final offlineUsersProvider = Provider<List<presence_model.UserPresence>>((ref) {
  return ref.watch(presenceProvider.notifier).getOfflineUsers();
});

// Specific user presence provider
final userPresenceProvider =
    Provider.family<presence_model.UserPresence?, String>((ref, userId) {
      return ref.watch(presenceProvider.notifier).getUserPresence(userId);
    });
