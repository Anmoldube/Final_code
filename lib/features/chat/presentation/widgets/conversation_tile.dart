import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'user_avatar.dart';

class ConversationTile extends ConsumerWidget {
  final ConversationModel conversation;
  final dynamic currentUser;
  final VoidCallback onTap;
  final VoidCallback? onRead;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUser,
    required this.onTap,
    this.onRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = currentUser?.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDividerColor
              : AppTheme.lightDividerColor,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(currentUserId, isDark),
        title: _buildTitle(context, currentUserId, isDark),
        subtitle: _buildSubtitle(context, currentUserId, isDark),
        trailing: _buildTrailing(context, isDark),
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
      ),
    );
  }

  Widget _buildAvatar(String? currentUserId, bool isDark) {
    if (conversation.isGroup) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: isDark
            ? AppTheme.darkDividerColor
            : AppTheme.lightDividerColor,
        child: Icon(
          Icons.group,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      );
    } else {
      final otherParticipant = conversation.getOtherParticipant(currentUserId);
      return UserAvatar(user: otherParticipant, size: 48, showStatus: true);
    }
  }

  Widget _buildTitle(BuildContext context, String? currentUserId, bool isDark) {
    final displayName = conversation.getDisplayName(currentUserId);

    return Row(
      children: [
        Expanded(
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: conversation.hasUnreadMessages
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (conversation.hasUnreadMessages) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${conversation.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    String? currentUserId,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildMessageTypeIcon(isDark),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _buildMessageText(currentUserId),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: conversation.hasUnreadMessages
                        ? (isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary)
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary),
                    fontWeight: conversation.hasUnreadMessages
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          conversation.lastMessageTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: conversation.hasUnreadMessages
                ? AppTheme.primaryColor
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            fontWeight: conversation.hasUnreadMessages
                ? FontWeight.w500
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (conversation.hasUnreadMessages) ...[
          Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
        ] else ...[
          Icon(
            Icons.done_all,
            size: 16,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ],
      ],
    );
  }

  Widget _buildMessageTypeIcon(bool isDark) {
    switch (conversation.lastMessageType) {
      case MessageType.image:
        return Icon(
          Icons.image,
          size: 16,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        );
      case MessageType.video:
        return Icon(
          Icons.videocam,
          size: 16,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        );
      case MessageType.audio:
        return Icon(
          Icons.mic,
          size: 16,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        );
      case MessageType.file:
        return Icon(
          Icons.attach_file,
          size: 16,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        );
      case MessageType.text:
      default:
        return const SizedBox.shrink();
    }
  }

  String _buildMessageText(String? currentUserId) {
    final lastMessage = conversation.lastMessagePreview;

    if (conversation.isGroup && conversation.lastMessageSender != null) {
      final senderName = conversation.lastMessageSender!.id == currentUserId
          ? 'You'
          : conversation.lastMessageSender!.displayName;
      return '$senderName: $lastMessage';
    }

    return lastMessage;
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conversation.hasUnreadMessages)
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.pop(context);
                  onRead?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mute functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
