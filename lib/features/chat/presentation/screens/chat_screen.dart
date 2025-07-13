import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/services/simple_presence_service.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/models/presence_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/widgets/connectivity_status.dart';
import '../../../../core/widgets/sync_status_widget.dart';
import '../../../../core/widgets/simple_presence_indicator.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/message_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/message_status_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/user_avatar.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/group_info_dialog.dart';
import '../widgets/file_attachment_preview.dart';
import '../widgets/file_upload_progress.dart';
import 'file_gallery_screen.dart';
import 'message_search_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isGroup = false,
    this.avatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  int _previousMessageCount = 0;
  bool _showScrollToBottomButton = false;
  Timer? _markAsReadTimer;
  Timer? _refreshTimer;
  final Set<String> _markedAsRead = {};

  // File sharing state
  final List<FilePickResult> _selectedFiles = [];
  List<FileUploadProgressItem> _uploadingFiles = [];
  bool _isUploading = false; // Restored: used in file upload logic

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load messages when chat opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider.notifier).loadMessages(widget.chatId);
      // Scroll to bottom after messages are loaded
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
      // Join the chat room via socket (for presence, typing, etc.)
      SocketService.instance.joinChat(widget.chatId);
      // Always scroll to bottom on open
      Future.delayed(const Duration(milliseconds: 200), () {
        _scrollToBottom();
      });
      // Mark messages as read after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        _markVisibleMessagesAsRead();
      });
      // Refresh messages periodically to get latest read receipts
      _startPeriodicRefresh();
    });

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  // Removed: _setupSocketListeners. SocketEventHandler handles all socket events globally.

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh messages when app resumes to get latest read receipts
      debugPrint(
        '🔄 App resumed, refreshing messages for chat ${widget.chatId}',
      );
      ref.read(messageProvider.notifier).loadMessages(widget.chatId);
    }
  }

  void _startPeriodicRefresh() {
    // Refresh messages every 2 minutes to get latest read receipts (reduced frequency)
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      debugPrint(
        '🔄 Periodic refresh: refreshing messages for chat ${widget.chatId}',
      );
      // Use force refresh to get latest data
      ref.read(messageProvider.notifier).forceRefreshMessages(widget.chatId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _markAsReadTimer?.cancel();
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    // Don't clear messages from state - keep them cached for better performance
    // Only clear if we need to force refresh (e.g., on logout)
    super.dispose();
  }

  void _onScroll() {
    // For reversed ListView, being at bottom means being at minScrollExtent
    final isAtBottom =
        _scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100;

    // Mark visible messages as read
    _scheduleMarkAsRead();

    setState(() {
      _showScrollToBottomButton = !isAtBottom;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // For reversed ListView, 0.0 is the bottom
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scheduleMarkAsRead() {
    _markAsReadTimer?.cancel();
    _markAsReadTimer = Timer(const Duration(milliseconds: 500), () {
      _markVisibleMessagesAsRead();
    });
  }

  void _markVisibleMessagesAsRead() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('❌ Current user is null, cannot mark messages as read');
      return;
    }

    final messages = ref.read(messagesForChatProvider(widget.chatId));
    final messageStatusNotifier = ref.read(messageStatusProvider.notifier);

    debugPrint('🔍 Checking ${messages.length} messages for read status');

    for (final message in messages) {
      // Only mark messages from other users as read
      if (message.sender.id != currentUser.id &&
          !_markedAsRead.contains(message.id) &&
          message.status != MessageStatus.read) {
        // Mark as read via socket
        debugPrint(
          '📖 Marking message as read: ${message.id} from ${message.sender.displayName}',
        );
        messageStatusNotifier.markAsRead(message.id, chatId: widget.chatId);
        _markedAsRead.add(message.id);
      } else {
        debugPrint(
          '⏭️ Skipping message ${message.id}: sender=${message.sender.id}, currentUser=${currentUser.id}, alreadyMarked=${_markedAsRead.contains(message.id)}, status=${message.status}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesForChatProvider(widget.chatId));
    final messageState = ref.watch(messageProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll to bottom when new messages arrive
    if (messages.length > _previousMessageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // For reversed ListView, check if user is near top (within 200 pixels) or if this is the first load
          final isNearBottom =
              _scrollController.position.pixels <=
              _scrollController.position.minScrollExtent + 200;

          // Always scroll to bottom on first load or when user is near bottom
          if (isNearBottom || _previousMessageCount == 0) {
            _scrollToBottom();
          } else {
            // Show scroll to bottom button if user is not near bottom
            setState(() {
              _showScrollToBottomButton = true;
            });
          }
        }
      });
      _previousMessageCount = messages.length;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1419) // Dark background similar to WhatsApp
          : const Color(0xFFE5DDD5), // WhatsApp-like background color
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Connectivity status bar
          const ConnectivityStatus(),

          // Sync status widget
          const SyncStatusWidget(),

          // Messages list
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(
                  messages,
                  messageState.isLoading,
                  currentUser,
                ),

                // Scroll to bottom button
                if (_showScrollToBottomButton)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: AppTheme.primaryColor,
                      onPressed: _scrollToBottom,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Typing indicator
          if (_isTyping) ...[
            const TypingIndicator(),
            const SizedBox(height: 8),
          ],

          // File upload progress
          if (_uploadingFiles.isNotEmpty) ...[
            MultipleFileUploadProgress(
              files: _uploadingFiles,
              onCancelAll: _cancelAllUploads,
            ),
          ],

          // Selected files preview
          if (_selectedFiles.isNotEmpty) ...[
            FileSelectionPreview(
              files: _selectedFiles,
              onRemove: _removeSelectedFile,
              onClearAll: _clearSelectedFiles,
            ),
          ],

          // Message input
          MessageInput(
            controller: _messageController,
            onSendMessage: sendMessage,
            onTyping: handleTyping,
            onFilePick: handleFilePick,
            onImagePick: handleImagePick,
            hasSelectedFiles: _selectedFiles.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(
    List<dynamic> messages,
    bool isLoading,
    dynamic currentUser,
  ) {
    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 Pull to refresh: force refreshing messages');
        await ref
            .read(messageProvider.notifier)
            .forceRefreshMessages(widget.chatId);
      },
      child: ListView.builder(
        controller: _scrollController,
        // Reverse the ListView to show newest messages at bottom
        reverse: true,
        // Use custom scroll physics for natural feel
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        itemCount: messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // When reversed, we need to flip the index to keep messages in chronological order
          final reversedIndex = messages.length - 1 - index;

          if (reversedIndex < 0 && isLoading) {
            // Loading indicator at the top when loading older messages
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (reversedIndex < 0) return null;

          final message = messages[reversedIndex];
          final isMe = message.sender.id == currentUser?.id;
          final showAvatar = !isMe && widget.isGroup;

          // Debug logging
          debugPrint(
            '🎯 Message: ${message.id} sender: ${message.sender.id}, currentUser: ${currentUser?.id}, isMe: $isMe',
          );

          // Check if we should show date separator
          final shouldShowDateSeparator =
              reversedIndex == messages.length - 1 ||
              !_isSameDay(
                message.createdAt,
                messages[reversedIndex + 1].createdAt,
              );

          return Column(
            children: [
              if (shouldShowDateSeparator) ...[
                _buildDateSeparator(message.createdAt),
                const SizedBox(height: 12),
              ],
              MessageBubble(
                message: message,
                isMe: isMe,
                showAvatar: showAvatar,
                // Show time for the last message in a group or if sender changes
                showTime: _shouldShowTime(messages, reversedIndex),
                onReply: () => replyToMessage(message),
                onEdit: isMe ? () => editMessage(message) : null,
                onDelete: isMe ? () => deleteMessage(message) : null,
              ),
              const SizedBox(height: 2),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Consumer(
        builder: (context, ref, child) {
          // Get chat data to show real member count
          final chatState = ref.watch(chatProvider);
          final currentChat = chatState.chats.cast<ChatModel?>().firstWhere(
            (chat) => chat?.id == widget.chatId,
            orElse: () => null,
          );

          return GestureDetector(
            onTap: widget.isGroup && currentChat != null
                ? () => showGroupInfoDialog(context, currentChat)
                : null,
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: widget.isGroup && currentChat != null
                      ? () => showGroupInfoDialog(context, currentChat)
                      : null,
                  child: UserAvatar(
                    avatarUrl: widget.avatarUrl,
                    size: 32,
                    showStatus: !widget.isGroup,
                  ),
                ),

                const SizedBox(width: 12),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!widget.isGroup) ...[
                        const SizedBox(height: 2),
                        Consumer(
                          builder: (context, ref, child) {
                            final currentUser = ref.watch(currentUserProvider);
                            final otherParticipant = currentChat
                                ?.getOtherParticipant(currentUser?.id ?? '');

                            if (otherParticipant?.id == null) {
                              return Text(
                                'Offline',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            }

                            return _buildEnhancedPresenceStatus(
                              otherParticipant!.id,
                              context,
                            );
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              currentChat != null
                                  ? '${currentChat.participants.length} members'
                                  : 'Group chat',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (widget.isGroup) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        // File gallery button
        IconButton(
          icon: const Icon(Icons.folder_outlined),
          onPressed: () => _openFileGallery(),
          tooltip: 'View Files',
        ),

        // Search button
        IconButton(
          icon: const Icon(Icons.search_outlined),
          onPressed: () => _openSearch(),
          tooltip: 'Search Messages',
        ),

        // More options
        PopupMenuButton<String>(
          onSelected: handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 12),
                  Text('Search'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off_outlined),
                  SizedBox(width: 12),
                  Text('Mute'),
                ],
              ),
            ),
            if (widget.isGroup) ...[
              const PopupMenuItem(
                value: 'group_info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('Group Info'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'clear_chat',
              child: Row(
                children: [
                  Icon(Icons.delete_outline),
                  SizedBox(width: 12),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    // Use TimestampService to get consistent current time
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      // Use DD/MM/YYYY format with proper padding
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      dateText = '$day/$month/${date.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _shouldShowTime(List<dynamic> messages, int index) {
    if (index >= messages.length - 1) {
      return true; // Always show time for the newest message
    }

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    // Show time if messages are from different senders
    if (currentMessage.sender.id != nextMessage.sender.id) return true;

    // Show time if messages are more than 5 minutes apart
    final timeDiff = nextMessage.createdAt.difference(currentMessage.createdAt);
    return timeDiff.inMinutes > 5;
  }

  void sendMessage(String content, {List<String>? attachments}) {
    // If files are selected, upload them instead of sending text message
    if (_selectedFiles.isNotEmpty) {
      _uploadFiles();
      return;
    }

    if (content.trim().isEmpty &&
        (attachments == null || attachments.isEmpty)) {
      return;
    }

    ref
        .read(messageProvider.notifier)
        .sendMessage(
          chatId: widget.chatId,
          content: content.trim(),
          attachments: attachments,
        );

    // Note: Text field is cleared by MessageInput widget
    _scrollToBottom();
  }

  void handleTyping(bool typing) {
    setState(() {
      _isTyping = typing;
    });

    // Implement typing indicator socket emission here
  }

  void handleFilePick() async {
    try {
      final files = await FileService.instance.pickMultipleFiles(maxFiles: 5);

      if (files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void handleImagePick() async {
    try {
      final files = await FileService.instance.pickImages(maxImages: 5);

      if (files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void replyToMessage(dynamic message) {
    // Implement reply functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Reply to: ${message.content}')));
  }

  void editMessage(dynamic message) {
    // Implement edit functionality
    _messageController.text = message.content;
    // Focus on input field
  }

  void deleteMessage(dynamic message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(messageProvider.notifier)
                  .deleteMessage(chatId: widget.chatId, messageId: message.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // void startVideoCall() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Video call feature will be implemented')),
  //   );
  // }

  // void startVoiceCall() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Voice call feature will be implemented')),
  //   );
  // }

  void _openFileGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            FileGalleryScreen(chatId: widget.chatId, chatName: widget.chatName),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageSearchScreen(
          chatId: widget.chatId,
          chatName: widget.chatName,
        ),
      ),
    );
  }

  void clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(messageProvider.notifier).clearChat(widget.chatId);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // File management methods
  void _removeSelectedFile(FilePickResult file) {
    setState(() {
      _selectedFiles.removeWhere((f) => f.path == file.path);
    });
  }

  void _clearSelectedFiles() {
    setState(() {
      _selectedFiles.clear();
    });
  }

  void _cancelAllUploads() {
    setState(() {
      _uploadingFiles.clear();
      _isUploading = false;
    });
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadingFiles = _selectedFiles.map((file) {
        return FileUploadProgressItem(
          fileName: file.name,
          progress: 0.0,
          fileSize: file.size,
          onCancel: () => _cancelFileUpload(file.name),
        );
      }).toList();
    });

    try {
      final caption = _messageController.text.trim();

      // Clear message input and selected files
      _messageController.clear();
      final selectedFilesCopy = List<FilePickResult>.from(_selectedFiles);
      setState(() {
        _selectedFiles.clear();
      });

      // Upload files using the new method that supports both web and mobile
      final results = await FileService.instance.uploadMultipleFileResults(
        fileResults: selectedFilesCopy,
        chatId: widget.chatId,
        caption: caption.isNotEmpty ? caption : null,
        onProgress: (fileName, progress) {
          setState(() {
            final index = _uploadingFiles.indexWhere(
              (file) => file.fileName == fileName,
            );
            if (index >= 0) {
              _uploadingFiles[index] = _uploadingFiles[index].copyWith(
                progress: progress,
              );
            }
          });
        },
      );

      // Handle upload results
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final fileName = selectedFilesCopy[i].name;

        setState(() {
          final index = _uploadingFiles.indexWhere(
            (file) => file.fileName == fileName,
          );
          if (index >= 0) {
            _uploadingFiles[index] = _uploadingFiles[index].copyWith(
              progress: 1.0,
              isCompleted: result.success,
              hasError: !result.success,
              errorMessage: result.error,
            );
          }
        });

        if (result.success) {
          // Refresh messages to show the new message with attachment
          ref.read(messageProvider.notifier).loadMessages(widget.chatId);
        }
      }

      // Clear upload progress after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _uploadingFiles.clear();
            _isUploading = false;
          });
        }
      });
    } catch (e) {
      // Handle upload error
      setState(() {
        for (int i = 0; i < _uploadingFiles.length; i++) {
          _uploadingFiles[i] = _uploadingFiles[i].copyWith(
            hasError: true,
            errorMessage: e.toString(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelFileUpload(String fileName) {
    setState(() {
      _uploadingFiles.removeWhere((file) => file.fileName == fileName);
    });
  }

  /// Handles actions from the app bar popup menu
  void handleMenuAction(String value) {
    switch (value) {
      case 'view_profile':
        // Implement view profile logic here
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('View Profile tapped')));
        break;
      case 'search':
        _openSearch();
        break;
      case 'mute':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mute tapped')));
        break;
      case 'group_info':
        final chatState = ref.read(chatProvider);
        final currentChat = chatState.chats.cast<ChatModel?>().firstWhere(
          (chat) => chat?.id == widget.chatId,
          orElse: () => null,
        );
        if (currentChat != null) {
          showGroupInfoDialog(context, currentChat);
        }
        break;
      case 'clear_chat':
        clearChat();
        break;
    }
  }

  // Enhanced presence status display for one-on-one chats
  Widget _buildEnhancedPresenceStatus(String userId, BuildContext context) {
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
                ' ', //TODO Status text should be empty initially`
                style: Theme.of(context).textTheme.bodySmall,
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: PresenceState.offline.color,
                ),
              ),
            ],
          );
        }

        // Show custom status prominently if available
        if (presence.customStatus != null &&
            presence.customStatus!.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: presence.state.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: presence.state.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SimplePresenceIndicator(state: presence.state, size: 8),
                const SizedBox(width: 6),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 12,
                  color: presence.state.color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    presence.customStatus!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: presence.state.color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        // Default presence display
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimplePresenceIndicator(state: presence.state, size: 8),
            const SizedBox(width: 6),
            Text(
              presence.state.isOnline
                  ? presence.state.displayName
                  : presence.getLastSeenText(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: presence.state.color),
            ),
          ],
        );
      },
    );
  }
}
