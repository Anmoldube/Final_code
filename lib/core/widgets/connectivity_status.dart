import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/offline_service.dart';
import '../theme/app_theme.dart';

// Provider for connectivity status
final connectivityProvider = StreamProvider<bool>((ref) {
  return OfflineService().connectivityStream;
});

class ConnectivityStatus extends ConsumerWidget {
  final bool showAlways;

  const ConnectivityStatus({super.key, this.showAlways = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return connectivity.when(
      data: (isOnline) {
        if (isOnline && !showAlways) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: isOnline ? Colors.green : AppTheme.errorColor,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          child: Text(
            isOnline
                ? 'Online'
                : 'Offline - Changes will sync when connection is restored',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// A provider to check if we're offline
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (isOnline) => !isOnline,
    orElse: () => false,
  );
});
