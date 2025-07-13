import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';
import 'user_avatar.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final ChatModel chat;

  const AddMemberDialog({super.key, required this.chat});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<UserModel> _selectedUsers = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load available users when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).getAvailableUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    // Debounce the search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == value) {
        ref.read(chatProvider.notifier).getAvailableUsers(query: value);
      }
    });
  }

  void _toggleUserSelection(UserModel user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add each selected user to the group
      for (final user in _selectedUsers) {
        await ref
            .read(chatProvider.notifier)
            .addUserToGroup(widget.chat.id, user.id);
      }

      if (mounted) {
        Navigator.of(context).pop(_selectedUsers);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> availableUsers) {
    // Get current participant IDs
    final participantIds = widget.chat.participants.map((p) => p.id).toSet();

    // Filter out users who are already in the group
    final filteredUsers = availableUsers
        .where((user) => !participantIds.contains(user.id))
        .toList();

    // Apply search filter if query is not empty
    if (_searchQuery.isNotEmpty) {
      return filteredUsers.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.displayName.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    }

    return filteredUsers;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final availableUsers = _getFilteredUsers(chatState.availableUsers);

    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Members',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select users to add to "${widget.chat.name}"',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedUsers.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),

            // Users list
            Expanded(
              child: chatState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : availableUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No users available to add'
                                : 'No users found matching "$_searchQuery"',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableUsers.length,
                      itemBuilder: (context, index) {
                        final user = availableUsers[index];
                        final isSelected = _selectedUsers.contains(user);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: UserAvatar(
                              user: user,
                              size: 40,
                              showStatus: true,
                            ),
                            title: Text(
                              user.displayName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(user.email),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryColor,
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey,
                                  ),
                            onTap: () => _toggleUserSelection(user),
                          ),
                        );
                      },
                    ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedUsers.isEmpty || _isLoading
                        ? null
                        : _addSelectedMembers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Add ${_selectedUsers.length == 1 ? 'Member' : 'Members'} (${_selectedUsers.length})',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the add member dialog
Future<List<UserModel>?> showAddMemberDialog(
  BuildContext context,
  ChatModel chat,
) async {
  return await showDialog<List<UserModel>>(
    context: context,
    builder: (context) => AddMemberDialog(chat: chat),
  );
}
