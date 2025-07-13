import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import 'conversation_tile.dart';

class ConversationList extends ConsumerStatefulWidget {
  const ConversationList({super.key});

  @override
  ConsumerState<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<ConversationList> {
  @override
  void initState() {
    super.initState();
    // Load conversations when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(conversationProvider.notifier).refreshConversations();
      },
      child: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: _buildContent(conversationState, currentUser, isDark),
      ),
    );
  }

  Widget _buildContent(
    dynamic conversationState,
    dynamic currentUser,
    bool isDark,
  ) {
    if (conversationState.isLoading &&
        conversationState.conversations.isEmpty) {
      return _buildLoadingState();
    }

    if (conversationState.error != null &&
        conversationState.conversations.isEmpty) {
      return _buildErrorState(conversationState.error!, isDark);
    }

    final conversations =
        conversationState.sortedConversations as List<ConversationModel>;
    final oneOnOneConversations = conversations
        .where((conversation) => !conversation.isGroupChat)
        .toList();

    if (oneOnOneConversations.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return _buildConversationList(conversations, currentUser, isDark);
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load conversations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(conversationProvider.notifier).loadConversations();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to begin chatting',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    List<ConversationModel> conversations,
    dynamic currentUser,
    bool isDark,
  ) {
    // Filter to show only one-on-one conversations (not group chats)
    final oneOnOneConversations = conversations
        .where((conversation) => !conversation.isGroupChat)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: oneOnOneConversations.length,
      itemBuilder: (context, index) {
        final conversation = oneOnOneConversations[index];

        return ConversationTile(
          conversation: conversation,
          currentUser: currentUser,
          onTap: () => _handleConversationTap(conversation, currentUser),
          onRead: () => _handleMarkAsRead(conversation),
        );
      },
    );
  }

  void _handleConversationTap(
    ConversationModel conversation,
    dynamic currentUser,
  ) {
    // Mark conversation as read when opened
    if (conversation.hasUnreadMessages) {
      ref
          .read(conversationProvider.notifier)
          .markConversationAsRead(conversation.id);
    }

    // Navigate to chat screen
    final chatName = conversation.getDisplayName(currentUser?.id);
    final isGroup = conversation.isGroupChat;
    final avatarUrl = conversation.isGroupChat
        ? null
        : conversation.participants
              .firstWhere(
                (user) => user.id != currentUser?.id,
                orElse: () => conversation.participants.first,
              )
              .avatar;

    context.push(
      '/home/chat/${conversation.id}?name=${Uri.encodeComponent(chatName)}&isGroup=$isGroup${avatarUrl != null ? '&avatarUrl=${Uri.encodeComponent(avatarUrl)}' : ''}',
    );
  }

  void _handleMarkAsRead(ConversationModel conversation) {
    if (conversation.hasUnreadMessages) {
      ref
          .read(conversationProvider.notifier)
          .markConversationAsRead(conversation.id);
    }
  }
}
