import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/chat_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/chat_debug_service.dart';
import 'user_avatar.dart';
import 'group_access_guide.dart';
import 'presence_status.dart';
import 'add_member_dialog.dart';

class GroupInfoDialog extends ConsumerWidget {
  final ChatModel chat;

  const GroupInfoDialog({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Debug the chat when opening group info
    ChatDebugService.debugChatParticipants(chat);
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  GroupAvatar(
                    users: chat.participants,
                    groupAvatarUrl: chat.avatar,
                    size: 60,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${chat.participants.length} members',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap on a member to view their profile',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey, fontSize: 11),
                        ),
                        // Debug info
                        Text(
                          'Debug: ${chat.participants.map((p) => p.id).toSet().length} unique IDs',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.orange, fontSize: 10),
                        ),
                        if (chat.description != null &&
                            chat.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            chat.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => showGroupAccessGuide(context),
                        tooltip: 'Help',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Members list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chat.participants.length,
                itemBuilder: (context, index) {
                  final participant = chat.participants[index];
                  final isAdmin = chat.admin?.id == participant.id;

                  return ListTile(
                    leading: UserAvatar(
                      user: participant,
                      size: 40,
                      showStatus: true,
                    ),
                    title: Text(
                      participant.displayName,
                      style: TextStyle(
                        fontWeight: isAdmin
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin
                              ? 'Admin • ${participant.email}'
                              : participant.email,
                          style: TextStyle(
                            color: isAdmin ? AppTheme.primaryColor : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        UserPresenceWidget(
                          userId: participant.id,
                          showIcon: false,
                          showLastSeen: true,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: isAdmin
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      // TODO: Show user profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${participant.displayName}\'s profile',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Actions
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
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();

                      // Show add member dialog
                      final addedUsers = await showAddMemberDialog(
                        context,
                        chat,
                      );

                      if (addedUsers != null && addedUsers.isNotEmpty) {
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              addedUsers.length == 1
                                  ? '${addedUsers.first.displayName} added to group'
                                  : '${addedUsers.length} members added to group',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Member'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Debug button to help identify participant count issues
                      ChatDebugService.debugChatParticipants(chat);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Debug info logged to console. Participants: ${chat.participants.length}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implement leave group functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Leave group functionality coming soon',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Leave Group'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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

// Helper function to show the group info dialog
void showGroupInfoDialog(BuildContext context, ChatModel chat) {
  showDialog(
    context: context,
    builder: (context) => GroupInfoDialog(chat: chat),
  );
}
