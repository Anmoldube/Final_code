import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../../core/providers/presence_provider.dart';
import '../../../../core/models/presence_model.dart' as presence_model;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_list_item.dart';

import '../widgets/status_indicator.dart';
import '../widgets/user_avatar.dart';
import '../widgets/create_chat_dialog.dart';
import '../widgets/group_info_dialog.dart';
import '../widgets/avatar_preview_screen.dart';
import '../widgets/conversation_list.dart';
import '../widgets/group_conversation_list.dart';
import '../providers/conversation_provider.dart';
import '../../../files/presentation/screens/files_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load chats, conversations, and available users when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadChats();
      ref.read(chatProvider.notifier).getAvailableUsers();
      ref.read(conversationProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final currentUser = ref.watch(currentUserProvider);
      final chatState = ref.watch(chatProvider);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.darkBackground
            : AppTheme.lightBackground,
        body: Column(
          children: [
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 370,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? AppTheme.darkDividerColor
                              : AppTheme.lightDividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header with user info
                        _buildHeader(currentUser, isDark),

                        // Tabs
                        _buildTabs(),

                        // Chat list
                        Expanded(child: _buildChatList(chatState, isDark)),
                      ],
                    ),
                  ),

                  // Main content area
                  Expanded(child: _buildMainContent(isDark)),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('❌ HomeScreen build error: $e');
      print('Stack trace: $stackTrace');

      // Return error screen
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Something went wrong'),
              const SizedBox(height: 8),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to reload the screen
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(dynamic currentUser, bool isDark) {
    final currentUserPresence = ref.watch(currentUserPresenceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkDividerColor
                : AppTheme.lightDividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          UserAvatar(user: currentUser, size: 40, showStatus: true),

          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.displayName ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StatusIndicator(
                      status:
                          currentUserPresence?.state.value ??
                          currentUser?.status?.value ??
                          '',
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getDisplayStatus(currentUserPresence, currentUser),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Row(
                  children: [
                    Icon(Icons.edit_note),
                    SizedBox(width: 12),
                    Text('Set Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'files',
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined),
                    SizedBox(width: 12),
                    Text('My Files'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'avatar_preview',
                child: Row(
                  children: [
                    Icon(Icons.face_outlined),
                    SizedBox(width: 12),
                    Text('Avatar System'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_outlined),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Conversations'),
          Tab(text: 'Groups'),
        ],
      ),
    );
  }

  Widget _buildChatList(dynamic chatState, bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Conversations (WhatsApp-like sorted list)
        const ConversationList(),

        // Group chats
        const GroupConversationList(),
      ],
    );
  }

  Widget _buildChatListView({
    required List<dynamic> chats,
    required bool isLoading,
    required bool isEmpty,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    final chatState = ref.watch(chatProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no chats exist, show available users to start conversations
    if (isEmpty && chatState.availableUsers.isNotEmpty) {
      return Column(
        children: [
          // Show message about starting conversations
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start Your First Conversation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a user below to start chatting',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Available users list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: chatState.availableUsers.length,
              itemBuilder: (context, index) {
                final user = chatState.availableUsers[index];

                // Filter out current user
                if (currentUser != null && user.id == currentUser.id) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: UserAvatar(user: user, size: 48, showStatus: true),
                    title: Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: _buildUserSubtitle(user),
                    trailing: Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    onTap: () => _startChatWithUser(user),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Show empty state if no chats and no users
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // Show existing chats
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          onTap: () => _openChat(chat),
          onLongPress: chat.isGroup ? () => _showGroupInfo(chat) : null,
        );
      },
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 96,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'ADRDE Chat',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a chat to start messaging',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateChatDialog,
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'status':
        _showQuickStatusDialog();
        break;
      case 'profile':
        context.go('/home/profile');
        break;
      case 'files':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FilesScreen(),
          ),
        );
        break;
      case 'settings':
        context.go('/home/settings');
        break;
      case 'avatar_preview':
        showAvatarPreview(context);
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _showQuickStatusDialog() {
    final quickStatuses = [
      {'text': 'In a meeting', 'emoji': '📅'},
      {'text': 'On lunch', 'emoji': '🍽️'},
      {'text': 'Working remotely', 'emoji': '🏠'},
      {'text': 'In focus time', 'emoji': '🎯'},
      {'text': 'On a call', 'emoji': '📞'},
      {'text': 'Be right back', 'emoji': '⏰'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clear status option
            ListTile(
              leading: const Icon(Icons.clear, color: Colors.grey),
              title: const Text('Clear status'),
              onTap: () {
                Navigator.of(context).pop();
                _setQuickStatus(null);
              },
            ),
            const Divider(),
            // Quick status options
            ...quickStatuses.map(
              (status) => ListTile(
                leading: Text(
                  status['emoji']!,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(status['text']!),
                onTap: () {
                  Navigator.of(context).pop();
                  _setQuickStatus(status['text']!);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home/profile');
            },
            child: const Text('More Options'),
          ),
        ],
      ),
    );
  }

  void _setQuickStatus(String? status) async {
    try {
      await ref
          .read(presenceProvider.notifier)
          .setUserStatus(
            presence_model.PresenceState.online,
            customStatus: status,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status != null ? 'Status set to: $status' : 'Status cleared',
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _openChat(dynamic chat) {
    final currentUser = ref.read(currentUserProvider);
    context.pushNamed(
      'chat',
      pathParameters: {'chatId': chat.id},
      queryParameters: {
        'name': chat.getDisplayName(currentUser?.id),
        'isGroup': chat.isGroup.toString(),
        if (chat.getDisplayAvatar(currentUser?.id).isNotEmpty)
          'avatarUrl': chat.getDisplayAvatar(currentUser?.id),
      },
    );
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateChatDialog(),
    );
  }

  void _showGroupInfo(dynamic chat) {
    showGroupInfoDialog(context, chat);
  }

  Future<void> _startChatWithUser(dynamic user) async {
    try {
      print('💬 Starting chat with user: ${user.displayName} (${user.id})');

      final result = await ref
          .read(chatProvider.notifier)
          .createOrGetDirectChat(user.id);

      if (result != null && mounted) {
        print('✅ Chat created/found successfully: ${result.id}');
        _openChat(result);
      } else {
        print('❌ Failed to create/find chat');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to start chat')));
        }
      }
    } catch (e) {
      print('❌ Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
      }
    }
  }

  String _getDisplayStatus(dynamic currentUserPresence, dynamic currentUser) {
    // If presence has a custom status, show it
    if (currentUserPresence?.customStatus != null &&
        currentUserPresence!.customStatus!.isNotEmpty) {
      return currentUserPresence.customStatus!;
    }

    // Otherwise show the presence state or user status
    if (currentUserPresence != null) {
      return currentUserPresence.state.displayName;
    }

    // Fallback to user status
    return currentUser?.status?.displayName ?? '';
  }

  Widget _buildUserSubtitle(dynamic user) {
    final userPresence = ref.watch(userPresenceProvider(user.id));

    // If user has a custom status, show it with an icon
    if (userPresence?.customStatus != null &&
        userPresence!.customStatus!.isNotEmpty) {
      return Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              userPresence.customStatus!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: userPresence.state.color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Otherwise show email with presence state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        if (userPresence != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: userPresence.state.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                userPresence.state.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: userPresence.state.color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
