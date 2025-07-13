import 'package:flutter/material.dart';

import '../../../../core/models/presence_model.dart';
import '../../../../core/services/simple_presence_service.dart';
import '../../../../core/widgets/simple_presence_indicator.dart';

class PresenceStatus extends StatelessWidget {
  final String userId;
  final bool showLastSeen;
  final TextStyle? textStyle;

  const PresenceStatus({
    super.key,
    required this.userId,
    this.showLastSeen = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, UserPresence>>(
      stream: SimplePresenceService.instance.presenceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SimplePresenceIndicator(state: PresenceState.offline, size: 8),
              const SizedBox(width: 6),
              Text(
                ' ',
                style: textStyle ?? Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }

        final presence = SimplePresenceService.instance.getUserPresence(userId);

        if (presence == null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SimplePresenceIndicator(state: PresenceState.offline, size: 8),
              const SizedBox(width: 6),
              Text(
                'Offline',
                style:
                    textStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PresenceState.offline.color,
                    ),
              ),
            ],
          );
        }

        // Show custom status if available, otherwise show presence state
        String displayText;
        if (presence.customStatus != null &&
            presence.customStatus!.isNotEmpty) {
          displayText = presence.customStatus!;
        } else if (showLastSeen && !presence.state.isOnline) {
          displayText = presence.getLastSeenText();
        } else {
          displayText = presence.state.displayName;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimplePresenceIndicator(state: presence.state, size: 8),
            const SizedBox(width: 6),
            // Add custom status icon if present
            if (presence.customStatus != null &&
                presence.customStatus!.isNotEmpty) ...[
              Icon(
                Icons.chat_bubble_outline,
                size: 12,
                color: presence.state.color,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                displayText,
                style:
                    textStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: presence.state.color,
                      fontWeight:
                          presence.customStatus != null &&
                              presence.customStatus!.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Widget to show presence in user profiles
class UserPresenceWidget extends StatelessWidget {
  final String userId;
  final bool showIcon;
  final bool showLastSeen;
  final TextStyle? textStyle;

  const UserPresenceWidget({
    super.key,
    required this.userId,
    this.showIcon = true,
    this.showLastSeen = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, UserPresence>>(
      stream: SimplePresenceService.instance.presenceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildOfflineWidget(context);
        }

        final presence = SimplePresenceService.instance.getUserPresence(userId);

        if (presence == null) {
          return _buildOfflineWidget(context);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: presence.state.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: presence.state.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                SimplePresenceIndicator(state: presence.state, size: 12),
                const SizedBox(width: 6),
              ],
              Text(
                presence.customStatus != null &&
                        presence.customStatus!.isNotEmpty
                    ? '💬 ${presence.customStatus!}'
                    : '${presence.state.emoji} ${presence.state.displayName}',
                style:
                    textStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: presence.state.color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (showLastSeen && !presence.state.isOnline) ...[
                const SizedBox(width: 4),
                Text(
                  '• ${presence.getLastSeenText()}',
                  style:
                      textStyle ??
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfflineWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PresenceState.offline.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PresenceState.offline.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            SimplePresenceIndicator(state: PresenceState.offline, size: 12),
            const SizedBox(width: 6),
          ],
          Text(
            '${PresenceState.offline.emoji} Offline',
            style:
                textStyle ??
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PresenceState.offline.color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
