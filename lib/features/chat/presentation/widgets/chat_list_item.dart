import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/chat_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'user_avatar.dart';
import 'group_info_dialog.dart';

class ChatListItem extends ConsumerWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const ChatListItem({
    super.key,
    required this.chat,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : chat.isDefault 
                ? AppTheme.primaryColor.withOpacity(0.05)  // Subtle highlight for default group
                : null,
        borderRadius: BorderRadius.circular(12),
        border: chat.isDefault 
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildAvatar(currentUser?.id),
        title: _buildTitle(context, currentUser?.id),
        subtitle: _buildSubtitle(context, currentUser?.id),
        trailing: _buildTrailing(context),
        onTap: onTap,
        onLongPress: onLongPress,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: isDark
            ? AppTheme.darkSurface.withOpacity(0.5)
            : Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Widget _buildAvatar(String? currentUserId) {
    if (chat.isGroup) {
      return GroupAvatar(
        users: chat.participants,
        groupAvatarUrl: chat.avatar,
        size: 48,
      );
    } else {
      // For one-on-one chats, show the other participant's avatar
      final otherParticipant = chat.getOtherParticipant(currentUserId);

      return UserAvatar(user: otherParticipant, size: 48, showStatus: true);
    }
  }

  Widget _buildTitle(BuildContext context, String? currentUserId) {
    return Row(
      children: [
        // Default group indicator
        if (chat.isDefault) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'DEFAULT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        Expanded(
          child: Text(
            chat.getDisplayName(currentUserId),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: chat.unreadCount > 0
                  ? FontWeight.w600
                  : chat.isDefault 
                      ? FontWeight.w600  // Make default group title bold
                      : FontWeight.w500,
              color: chat.isDefault 
                  ? AppTheme.primaryColor  // Highlight default group name
                  : (chat.unreadCount > 0 ? null : null),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Muted indicator
        if (chat.isMuted) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.volume_off,
            size: 16,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ],

        // Pinned indicator
        if (chat.isPinned) ...[
          const SizedBox(width: 4),
          Icon(Icons.push_pin, size: 16, color: AppTheme.primaryColor),
        ],
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context, String? currentUserId) {
    if (chat.lastMessage == null) {
      return Text(
        chat.isGroup
            ? '${chat.participants.length} members • Group created'
            : 'Start a conversation',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final lastMessage = chat.lastMessage!;
    String messagePreview = _getMessagePreview(lastMessage);

    return Row(
      children: [
        // Message status indicator for sent messages
        if (lastMessage.isFromCurrentUser(currentUserId)) ...[
          _buildMessageStatusIcon(lastMessage),
          const SizedBox(width: 4),
        ],

        // Sender name for group chats
        if (chat.isGroup && !lastMessage.isFromCurrentUser(currentUserId)) ...[
          Text(
            '${lastMessage.sender.displayName}: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ],

        // Message preview
        Expanded(
          child: Text(
            messagePreview,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: chat.unreadCount > 0
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Timestamp
            if (chat.lastMessage != null) ...[
              Text(
                _formatTimestamp(chat.lastMessage!.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: chat.unreadCount > 0
                      ? AppTheme.primaryColor
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Unread count badge
            if (chat.unreadCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chat.isMuted ? Colors.grey : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Group info button for group chats
        if (chat.isGroup) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onPressed: () => showGroupInfoDialog(context, chat),
            tooltip: 'Group Info',
          ),
        ],
      ],
    );
  }

  Widget _buildMessageStatusIcon(dynamic lastMessage) {
    IconData icon;
    Color? color;

    switch (lastMessage.status) {
      case 'sent':
        icon = Icons.check;
        color = Colors.grey;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case 'read':
        icon = Icons.done_all;
        color = AppTheme.primaryColor;
        break;
      case 'failed':
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }

  String _getMessagePreview(dynamic lastMessage) {
    if (lastMessage.content.isNotEmpty) {
      return lastMessage.content;
    }

    if (lastMessage.attachments.isNotEmpty) {
      final attachment = lastMessage.attachments.first;
      switch (attachment.type) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'audio':
          return '🎵 Audio';
        case 'document':
          return '📄 Document';
        default:
          return '📎 Attachment';
      }
    }

    return 'Message';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(timestamp);
    } else if (difference.inDays < 365) {
      // This year - show month and day
      return DateFormat('MMM d').format(timestamp);
    } else {
      // Show full date
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}

// Compact chat list item for search results
class CompactChatListItem extends ConsumerWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final String? searchQuery;

  const CompactChatListItem({
    super.key,
    required this.chat,
    this.onTap,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    return ListTile(
      dense: true,
      leading: chat.isGroup
          ? GroupAvatar(
              users: chat.participants,
              groupAvatarUrl: chat.avatar,
              size: 32,
            )
          : UserAvatar(
              user: chat.getOtherParticipant(currentUser?.id),
              size: 32,
            ),
      title: _buildHighlightedText(
        chat.getDisplayName(currentUser?.id),
        searchQuery,
        context,
      ),
      subtitle: chat.lastMessage != null
          ? _buildHighlightedText(
              chat.lastMessage!.content,
              searchQuery,
              context,
            )
          : null,
      trailing: chat.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildHighlightedText(
    String text,
    String? query,
    BuildContext context,
  ) {
    if (query == null || query.isEmpty) {
      return Text(text);
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(queryLower)) {
      return Text(text);
    }

    final spans = <TextSpan>[];
    final parts = text.split(RegExp(query, caseSensitive: false));

    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));

      if (i < parts.length - 1) {
        spans.add(
          TextSpan(
            text: query,
            style: TextStyle(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: DefaultTextStyle.of(context).style,
      ),
    );
  }
}

// Chat list item with swipe actions
class SwipeableChatListItem extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onMute;

  const SwipeableChatListItem({
    super.key,
    required this.chat,
    this.onTap,
    this.onArchive,
    this.onDelete,
    this.onPin,
    this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('chat_${chat.id}'),
      background: _buildSwipeBackground(context, isLeft: true),
      secondaryBackground: _buildSwipeBackground(context, isLeft: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Left swipe - archive
          onArchive?.call();
        } else {
          // Right swipe - delete
          onDelete?.call();
        }
        return false; // Don't actually dismiss, just trigger the action
      },
      child: ChatListItem(chat: chat, onTap: onTap),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: isLeft ? Colors.blue : Colors.red,
      child: Icon(
        isLeft ? Icons.archive_outlined : Icons.delete_outline,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
