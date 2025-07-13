import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'user_avatar.dart';
import 'search_bar_widget.dart';

class CreateChatDialog extends ConsumerStatefulWidget {
  const CreateChatDialog({super.key});

  @override
  ConsumerState<CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends ConsumerState<CreateChatDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();

  List<UserModel> _searchResults = [];
  final List<UserModel> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    print('🔄 Loading users...');
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(chatProvider.notifier).getAvailableUsers();
      final chatState = ref.read(chatProvider);
      final currentUser = ref.read(currentUserProvider);

      // Filter out current user from results
      final filteredUsers = chatState.availableUsers.where((user) {
        return currentUser == null || user.id != currentUser.id;
      }).toList();

      print('✅ Loaded ${chatState.availableUsers.length} users, filtered to ${filteredUsers.length}');
      setState(() {
        _searchResults = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to load users: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    }
  }

  void _searchUsers(String query) async {
    print('🔍 Searching users with query: "$query"');
    
    // If query is empty, load all users
    if (query.isEmpty) {
      await _loadUsers();
      return;
    }

    // Search users with API call
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(chatProvider.notifier).getAvailableUsers(query: query);
      final chatState = ref.read(chatProvider);
      final currentUser = ref.read(currentUserProvider);

      // Filter out current user from results
      final filteredUsers = chatState.availableUsers.where((user) {
        return currentUser == null || user.id != currentUser.id;
      }).toList();

      print('✅ Search returned ${chatState.availableUsers.length} users, filtered to ${filteredUsers.length}');
      setState(() {
        _searchResults = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Search failed: $e');
      setState(() {
        _isLoading = false;
      });

      // Fallback to local filtering if API search fails
      final chatState = ref.read(chatProvider);
      final currentUser = ref.read(currentUserProvider);
      final allUsers = chatState.availableUsers.where((user) {
        return currentUser == null || user.id != currentUser.id;
      }).toList();
      
      final filtered = allUsers.where((user) {
        return user.displayName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.username.toLowerCase().contains(query.toLowerCase());
      }).toList();

      print('📋 Local filter returned ${filtered.length} users');
      setState(() {
        _searchResults = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 8),
                Text(
                  'New Chat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: 'Direct Message'),
                Tab(text: 'Group Chat'),
              ],
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDirectMessageTab(isDark),
                  _buildGroupChatTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectMessageTab(bool isDark) {
    return Column(
      children: [
        // Search bar
        SearchBarWidget(
          controller: _searchController,
          hintText: 'Search users...',
          onChanged: _searchUsers,
        ),

        const SizedBox(height: 16),

        // User list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 64,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _buildUserTile(
                      user,
                      onTap: () {
                        _createDirectChat(user);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGroupChatTab(bool isDark) {
    return Column(
      children: [
        // Group name input
        TextField(
          controller: _groupNameController,
          decoration: InputDecoration(
            labelText: 'Group Name*',
            hintText: 'Enter group name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.group),
          ),
        ),

        const SizedBox(height: 16),

        // Group description input
        TextField(
          controller: _groupDescriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Enter group description',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // Selected users
        if (_selectedUsers.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBackground : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected (${_selectedUsers.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedUsers.map((user) {
                    return Chip(
                      avatar: UserAvatar(user: user, size: 24),
                      label: Text(user.displayName),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedUsers.remove(user);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Search bar
        SearchBarWidget(
          controller: _searchController,
          hintText: 'Search users to add...',
          onChanged: _searchUsers,
        ),

        const SizedBox(height: 16),

        // User list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isSelected = _selectedUsers.contains(user);

                    return _buildUserTile(
                      user,
                      isSelected: isSelected,
                      onTap: () {
                        // Show options: Direct Chat or Add to Group
                        _showUserActionDialog(user, isSelected);
                      },
                    );
                  },
                ),
        ),

        const SizedBox(height: 16),

        // Create group button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                _selectedUsers.isNotEmpty &&
                    _groupNameController.text.trim().isNotEmpty
                ? _createGroupChat
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create Group (${_selectedUsers.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(
    UserModel user, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: UserAvatar(user: user, size: 40, showStatus: true),
      title: Text(
        user.displayName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(user.email),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
      tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showUserActionDialog(UserModel user, bool isSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat with ${user.displayName}'),
        content: Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createDirectChat(user);
            },
            child: const Text('Start Direct Chat'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (isSelected) {
                  _selectedUsers.remove(user);
                } else {
                  _selectedUsers.add(user);
                }
              });
            },
            child: Text(isSelected ? 'Remove from Group' : 'Add to Group'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDirectChat(UserModel user) async {
    try {
      print('💬 Creating direct chat with user: ${user.displayName} (${user.id})');
      final result = await ref
          .read(chatProvider.notifier)
          .createOrGetDirectChat(user.id);

      if (mounted && result != null) {
        print('✅ Direct chat created successfully: ${result.id}');
        Navigator.pop(context, result);
      } else {
        print('❌ Direct chat creation returned null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create direct chat')),
          );
        }
      }
    } catch (e) {
      print('❌ Direct chat creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create chat: $e')));
      }
    }
  }

  Future<void> _createGroupChat() async {
    final name = _groupNameController.text.trim();
    final description = _groupDescriptionController.text.trim();

    print('👥 Creating group chat: "$name" with ${_selectedUsers.length} users');

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    try {
      final participantIds = _selectedUsers.map((u) => u.id).toList();
      print('📋 Participant IDs: $participantIds');
      
      final result = await ref
          .read(chatProvider.notifier)
          .createGroupChat(
            name: name,
            description: description.isNotEmpty ? description : null,
            participantIds: participantIds,
          );

      if (mounted && result != null) {
        print('✅ Group chat created successfully: ${result.id}');
        Navigator.pop(context, result);
      } else {
        print('❌ Group chat creation returned null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create group chat')),
          );
        }
      }
    } catch (e) {
      print('❌ Group chat creation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
      }
    }
  }
}

// Helper function to show create chat dialog
Future<dynamic> showCreateChatDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => const CreateChatDialog(),
  );
}
