import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/offline_service.dart';
import '../widgets/connectivity_status.dart';

// Provider for the offline service
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

// Provider for syncing offline data
final offlineSyncProvider = FutureProvider.autoDispose<void>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? false;

  if (isOnline) {
    await offlineService.syncOfflineData();
  }
});

// Provider for unsynchronized messages count
final unsyncedMessagesCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final messages = await offlineService.getUnsyncedMessages();
  return messages.length;
});

// Provider for unsynchronized chats count
final unsyncedChatsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final offlineService = ref.watch(offlineServiceProvider);
  final chats = await offlineService.getUnsyncedChats();
  return chats.length;
});

// Provider for total unsynchronized items count
final totalUnsyncedItemsProvider = FutureProvider.autoDispose<int>((ref) async {
  final messagesCount = await ref.watch(unsyncedMessagesCountProvider.future);
  final chatsCount = await ref.watch(unsyncedChatsCountProvider.future);
  return messagesCount + chatsCount;
});
