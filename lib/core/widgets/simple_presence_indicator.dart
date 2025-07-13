import 'package:flutter/material.dart';

import '../models/presence_model.dart';

// Simple presence indicator widget
class SimplePresenceIndicator extends StatelessWidget {
  final PresenceState state;
  final double size;
  final bool showBorder;

  const SimplePresenceIndicator({
    super.key,
    required this.state,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: state.color,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: size * 0.15)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: state.color.withOpacity(0.3),
                  blurRadius: size * 0.2,
                  spreadRadius: size * 0.1,
                ),
              ]
            : null,
      ),
      child: state == PresenceState.offline
          ? null
          : state == PresenceState.away
          ? Icon(state.icon, size: size * 0.6, color: Colors.white)
          : null,
    );
  }
}

// Presence status with text
class PresenceStatusWidget extends StatelessWidget {
  final PresenceState state;
  final String? lastSeenText;
  final bool showLastSeen;
  final TextStyle? textStyle;

  const PresenceStatusWidget({
    super.key,
    required this.state,
    this.lastSeenText,
    this.showLastSeen = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SimplePresenceIndicator(state: state, size: 12),
        const SizedBox(width: 6),
        Text(
          state.displayName,
          style:
              textStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: state.color,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (showLastSeen && lastSeenText != null && !state.isOnline) ...[
          const SizedBox(width: 4),
          Text(
            '• $lastSeenText',
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
    );
  }
}

// Avatar with presence indicator
class AvatarWithPresence extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final PresenceState presenceState;
  final double size;
  final VoidCallback? onTap;

  const AvatarWithPresence({
    super.key,
    this.avatarUrl,
    required this.displayName,
    required this.presenceState,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Avatar
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  )
                : null,
          ),

          // Presence indicator
          Positioned(
            bottom: 0,
            right: 0,
            child: SimplePresenceIndicator(
              state: presenceState,
              size: size * 0.3,
              showBorder: true,
            ),
          ),
        ],
      ),
    );
  }
}
