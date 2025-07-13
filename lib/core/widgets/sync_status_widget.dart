import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_provider.dart';
import '../theme/app_theme.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalUnsyncedItems = ref.watch(totalUnsyncedItemsProvider);

    return totalUnsyncedItems.when(
      data: (count) {
        if (count <= 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () => _syncNow(ref),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync, size: 16, color: AppTheme.warningColor),
                const SizedBox(width: 4),
                Text(
                  '$count item${count == 1 ? '' : 's'} waiting to sync',
                  style: TextStyle(fontSize: 12, color: AppTheme.warningColor),
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to sync now',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const SizedBox(height: 2, child: LinearProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _syncNow(WidgetRef ref) {
    ref.refresh(offlineSyncProvider);
  }
}
