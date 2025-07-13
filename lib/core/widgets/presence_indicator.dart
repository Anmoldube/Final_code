import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/presence_model.dart';
import '../providers/presence_provider.dart';
import '../theme/app_theme.dart';

// Presence indicator widget
class PresenceIndicator extends ConsumerWidget {
  final String userId;
  final double size;
  final bool showStatus;
  final bool showLastSeen;
  final bool showBorder;

  const PresenceIndicator({
    super.key,
    required this.userId,
    this.size = 12,
    this.showStatus = false,
    this.showLastSeen = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPresence = ref.watch(userPresenceProvider(userId));
    final settings = ref.watch(presenceSettingsProvider);

    if (userPresence == null || userPresence.state == PresenceState.offline) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        _buildStatusIndicator(userPresence, settings),

        if (showStatus) ...[
          const SizedBox(width: 4),
          _buildStatusText(context, userPresence, settings),
        ],

        if (showLastSeen && settings.showLastSeen) ...[
          const SizedBox(width: 4),
          _buildLastSeenText(context, userPresence),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(
    UserPresence presence,
    PresenceSettings settings,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: presence.state.color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: size * 0.15)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: presence.state.color.withOpacity(0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.1,
                ),
              ]
            : null,
      ),
      child: presence.state == PresenceState.offline
          ? null
          : presence.state == PresenceState.away ||
                presence.state == PresenceState.idle
          ? Icon(presence.state.icon, size: size * 0.6, color: Colors.white)
          : null,
    );
  }

  Widget _buildStatusText(
    BuildContext context,
    UserPresence presence,
    PresenceSettings settings,
  ) {
    return Text(
      presence.getStatusText(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: presence.state.color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLastSeenText(BuildContext context, UserPresence presence) {
    return Text(
      presence.getLastSeenText(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

// Detailed presence card widget
class PresenceCard extends ConsumerWidget {
  final String userId;
  final String userName;
  final String? userAvatar;

  const PresenceCard({
    super.key,
    required this.userId,
    required this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPresence = ref.watch(userPresenceProvider(userId));
    final settings = ref.watch(presenceSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userPresence == null || userPresence.state == PresenceState.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: userPresence.state.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with presence indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: userAvatar != null
                    ? NetworkImage(userAvatar!)
                    : null,
                child: userAvatar == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: PresenceIndicator(
                  userId: userId,
                  size: 12,
                  showBorder: true,
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      userPresence.state.icon,
                      size: 14,
                      color: userPresence.state.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      userPresence.getStatusText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: userPresence.state.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (settings.showLastSeen && !userPresence.isOnline) ...[
                  const SizedBox(height: 2),
                  Text(
                    userPresence.getLastSeenText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Presence list widget
class PresenceList extends ConsumerWidget {
  final List<String> userIds;
  final List<String> userNames;
  final List<String?> userAvatars;

  const PresenceList({
    super.key,
    required this.userIds,
    required this.userNames,
    required this.userAvatars,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPresences = ref.watch(userPresencesProvider);

    // Sort users by presence state
    final sortedUsers = List.generate(userIds.length, (index) {
      return {
        'userId': userIds[index],
        'userName': userNames[index],
        'userAvatar': userAvatars.length > index ? userAvatars[index] : null,
        'presence': userPresences[userIds[index]],
      };
    });

    sortedUsers.sort((a, b) {
      final aPresence = a['presence'] as UserPresence?;
      final bPresence = b['presence'] as UserPresence?;

      if (aPresence == null && bPresence == null) return 0;
      if (aPresence == null) return 1;
      if (bPresence == null) return -1;

      // Sort by presence state priority (online first, offline last)
      final aPriority = aPresence.state == PresenceState.online
          ? 0
          : aPresence.state == PresenceState.away
          ? 1
          : aPresence.state == PresenceState.idle
          ? 2
          : 3;

      final bPriority = bPresence.state == PresenceState.online
          ? 0
          : bPresence.state == PresenceState.away
          ? 1
          : bPresence.state == PresenceState.idle
          ? 2
          : 3;

      return aPriority.compareTo(bPriority);
    });

    return ListView.builder(
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PresenceCard(
            userId: user['userId'] as String,
            userName: user['userName'] as String,
            userAvatar: user['userAvatar'] as String?,
          ),
        );
      },
    );
  }
}

// Simple presence dot for avatars
class PresenceDot extends ConsumerWidget {
  final String userId;
  final double size;

  const PresenceDot({super.key, required this.userId, this.size = 8});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPresence = ref.watch(userPresenceProvider(userId));

    if (userPresence == null || userPresence.state == PresenceState.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: userPresence.state.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.2),
        boxShadow: [
          BoxShadow(
            color: userPresence.state.color.withOpacity(0.3),
            blurRadius: size * 0.3,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}
