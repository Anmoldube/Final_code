import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/models/chat_model.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/services/timestamp_service.dart';
import 'user_avatar.dart';
import 'file_attachment_preview.dart';
import 'message_status_widget.dart';
import '../providers/message_status_provider.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool showTime;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const MessageBubble({
    super.key,
    required this.message,
    this.isMe = false,
    this.showAvatar = false,
    this.showTime = false,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the latest message with status updates
    final messageWithStatus =
        ref.watch(messageWithStatusProvider(message.id)) ?? message;
    final isRetrying = ref.watch(messageRetryingProvider(message.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Debug logging
    debugPrint(
      '🎯 MessageBubble: Message ${message.id} original status: ${message.status}, with status: ${messageWithStatus.status}, readBy: ${messageWithStatus.readBy}',
    );

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
          bottom: 4,
        ),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!isMe && showAvatar) ...[
              UserAvatar(user: message.sender, size: 32),
              const SizedBox(width: 8),
            ] else if (!isMe && !showAvatar) ...[
              const SizedBox(width: 40),
            ],

            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Reply indicator
                  if (message.replyTo != null) ...[
                    _buildReplyIndicator(context, isDark),
                    const SizedBox(height: 4),
                  ],

                  // Main message bubble
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppTheme.primaryColor
                          : (isDark
                                ? AppTheme.darkSurface
                                : const Color(0xFFFFFFFF)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender name for group chats
                        if (!isMe && showAvatar) ...[
                          Text(
                            message.sender.displayName,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // Message content
                        if (message.content.isNotEmpty) ...[
                          _buildMessageContent(context, isDark),
                        ],

                        // File summary
                        if (message.attachments.isNotEmpty) ...[
                          if (message.content.isNotEmpty)
                            const SizedBox(height: 6),
                          _buildFileSummary(context, isDark),
                          const SizedBox(height: 4),
                        ],

                        // Attachments
                        if (message.attachments.isNotEmpty) ...[
                          FileAttachmentPreview(
                            attachments: message.attachments,
                            isMe: isMe,
                            onDownload: (attachment) =>
                                _downloadAttachment(context, attachment),
                            onOpen: (attachment) =>
                                _openAttachment(context, attachment),
                          ),
                        ],

                        // Message status and time with enhanced status widget
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Show retry indicator if retrying
                            if (isRetrying) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isMe
                                        ? Colors.white70
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Enhanced message status widget
                            MessageStatusWidget(
                              message: messageWithStatus,
                              isOwnMessage: isMe,
                              onRetry: messageWithStatus.status.canRetry
                                  ? () => _handleRetryMessage(
                                      ref,
                                      messageWithStatus.id,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Timestamp (removed duplicate, only show one time)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: EdgeInsets.only(left: isMe ? 40 : 0, right: isMe ? 0 : 40),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.darkBackground : Colors.grey[100])
            ?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.primaryColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo?.sender.displayName ?? 'Unknown',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            message.replyTo?.content ?? '',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isDark) {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: isMe
            ? Colors.white
            : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      children: message.attachments.map((attachment) {
        switch (attachment.type) {
          case 'image':
            return _buildImageAttachment(attachment);
          case 'video':
            return _buildVideoAttachment(attachment);
          case 'audio':
            return _buildAudioAttachment(attachment);
          case 'document':
            return _buildDocumentAttachment(attachment);
          default:
            return _buildGenericAttachment(attachment);
        }
      }).toList(),
    );
  }

  Widget _buildImageAttachment(dynamic attachment) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: attachment.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error, color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(dynamic attachment) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video thumbnail
          if (attachment.thumbnail != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: attachment.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],

          // Play button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioAttachment(dynamic attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audio_file,
            color: isMe ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name ?? 'Audio file',
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.duration != null) ...[
                  Text(
                    _formatDuration(attachment.duration),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentAttachment(dynamic attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDocumentIcon(attachment.name),
            color: isMe ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name ?? 'Document',
                  style: TextStyle(
                    color: isMe ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.size != null) ...[
                  Text(
                    _formatFileSize(attachment.size),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericAttachment(dynamic attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            color: isMe ? Colors.white : AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              attachment.name ?? 'Attachment',
              style: TextStyle(
                color: isMe ? Colors.white : null,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildMessageFooter: now only show time below bubble, not in footer

  /// Shows single tick if sent, double tick if read, for sent messages only.
  Widget _buildReadStatusIcon(BuildContext context) {
    // Get current user ID from ChatModel (set by auth provider)
    final currentUserId = ChatModel.currentUserId;
    // Defensive: if not available, fallback to no icon
    if (currentUserId.isEmpty) return SizedBox.shrink();

    // If message is not from current user, don't show ticks
    if (message.sender.id != currentUserId) return SizedBox.shrink();

    // If message is not synced or is local only, show offline icon
    if (!message.isSynced || message.isLocalOnly) {
      return Tooltip(
        message: 'Offline - Will be sent when you reconnect',
        child: Icon(Icons.offline_bolt, size: 14, color: AppTheme.warningColor),
      );
    }

    // readBy: list of user IDs who have read the message (including sender)
    final readBy = message.readBy ?? [];
    // Exclude sender from readBy
    final othersRead = readBy.where((id) => id != currentUserId).toList();

    // Double tick only if ALL recipients (except sender) have read (for 1-to-1, this means recipient has read)
    // For group chat, you may want to pass the list of all participant IDs to this widget for full accuracy
    // Here, we assume 1-to-1 chat: double tick if exactly one other user (recipient) has read
    if (othersRead.isNotEmpty) {
      return Icon(Icons.done_all, size: 14, color: Colors.blue);
    } else {
      return Icon(Icons.check, size: 14, color: Colors.grey);
    }
  }

  /// Handle retry message action
  void _handleRetryMessage(WidgetRef ref, String messageId) {
    final messageStatusNotifier = ref.read(messageStatusProvider.notifier);
    messageStatusNotifier.retryMessage(messageId);
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null) ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply?.call();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Message copied')));
              },
            ),
            if (isMe && onEdit != null) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            ],
            if (isMe && onDelete != null) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Format timestamp for detailed view (when showing time)
  // _formatTimestamp is unused, safe to remove

  // Format timestamp for message footer (compact format)
  String _formatMessageTimestamp(DateTime timestamp) {
    // Use TimestampService to ensure proper handling of timestamps
    final validatedTime = TimestampService.validateTimestamp(timestamp);
    final localTimestamp = validatedTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTimestamp);

    if (difference.inDays == 0) {
      // Today - show time in IST with AM/PM (e.g., "4:38 PM")
      return DateFormat('h:mm a').format(localTimestamp);
    } else if (difference.inDays == 1) {
      // Yesterday - show "Yesterday" with time
      return 'Yesterday ${DateFormat('h:mm a').format(localTimestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day name with time (e.g., "Monday 4:38 PM")
      return '${DateFormat('EEEE').format(localTimestamp)} ${DateFormat('h:mm a').format(localTimestamp)}';
    } else {
      // Show date and time (e.g., "15 Jul, 4:38 PM")
      return DateFormat('d MMM, h:mm a').format(localTimestamp);
    }
  }

  // Download attachment with comprehensive error handling
  void _downloadAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Downloading  27${attachment.displayName} 27...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // First, verify the file URL is accessible
      final isAccessible = await _verifyFileUrl(attachment.url);
      if (!isAccessible) {
        _showErrorSnackBar(
          context,
          'File not accessible. Server may be offline or file was removed.',
        );
        return;
      }

      if (kIsWeb) {
        // On web, try multiple approaches for download
        await _downloadFileWeb(context, attachment);
      } else {
        // On mobile, use file service with retry logic
        await _downloadFileMobile(context, attachment);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      _showErrorSnackBar(context, 'Download failed: ${_getErrorMessage(e)}');
    }
  }

  // Open attachment with error handling
  void _openAttachment(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    try {
      // First, verify the file URL is accessible
      final isAccessible = await _verifyFileUrl(attachment.url);
      if (!isAccessible) {
        _showErrorSnackBar(
          context,
          'File not accessible. Server may be offline or file was removed.',
        );
        return;
      }

      if (kIsWeb) {
        // On web, open file URL in new tab with fallback
        await _openFileWeb(context, attachment);
      } else {
        // On mobile, download and open
        await _openFileMobile(context, attachment);
      }
    } catch (e) {
      debugPrint('Open file error: $e');
      _showErrorSnackBar(
        context,
        'Could not open file: ${_getErrorMessage(e)}',
      );
    }
  }

  // Web-specific download with multiple approaches
  Future<void> _downloadFileWeb(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    try {
      // Normalize URL for LAN access
      final normalizedUrl = FileService.normalizeFileUrl(attachment.url);
      final uri = Uri.parse(normalizedUrl);

      debugPrint('Attempting to download: $normalizedUrl');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar(context, 'Opened: ${attachment.displayName}');
      } else {
        // Fallback: try opening in new tab
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        _showSuccessSnackBar(context, 'File opened in new tab');
      }
    } catch (e) {
      debugPrint('Web download error: $e');
      throw Exception('Web download failed: ${_getErrorMessage(e)}');
    }
  }

  // Web-specific file opening
  Future<void> _openFileWeb(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    try {
      // Normalize URL for LAN access
      final normalizedUrl = FileService.normalizeFileUrl(attachment.url);
      final uri = Uri.parse(normalizedUrl);

      debugPrint('Attempting to open: $normalizedUrl');

      // For images, try to open in same tab first
      if (attachment.fileType.toLowerCase() == 'image') {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        // For other files, open in new tab
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Web open error: $e');
      // Fallback to external application
      final normalizedUrl = FileService.normalizeFileUrl(attachment.url);
      final uri = Uri.parse(normalizedUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Mobile-specific download with retry logic
  Future<void> _downloadFileMobile(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    // Show downloading progress
    _showInfoSnackBar(
      context,
      '📥 Starting download: ${attachment.displayName}',
    );

    while (retryCount < maxRetries) {
      try {
        debugPrint(
          '📥 Download attempt ${retryCount + 1}/$maxRetries for: ${attachment.displayName}',
        );

        final result = await FileService.instance.downloadFile(
          fileUrl: attachment.url,
          fileName: attachment.displayName,
          onProgress: (progress) {
            debugPrint(
              '📥 Download progress: ${(progress * 100).toStringAsFixed(1)}%',
            );
          },
        );

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded: ${attachment.displayName}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => _openLocalFile(context, result.filePath!),
              ),
            ),
          );
          return;
        } else {
          if (retryCount == maxRetries - 1) {
            throw Exception(result.error ?? 'Download failed');
          }
        }
      } catch (e) {
        if (retryCount == maxRetries - 1) {
          rethrow;
        }
      }

      retryCount++;
      await Future.delayed(Duration(seconds: retryCount));
    }
  }

  // Mobile-specific file opening
  Future<void> _openFileMobile(
    BuildContext context,
    MessageAttachment attachment,
  ) async {
    final result = await FileService.instance.downloadFile(
      fileUrl: attachment.url,
      fileName: attachment.displayName,
    );

    if (result.success) {
      await _openLocalFile(context, result.filePath!);
    } else {
      throw Exception(result.error ?? 'Could not download file for opening');
    }
  }

  // Open local file (mobile only) - only one declaration
  Future<void> _openLocalFile(BuildContext context, String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Could not open file: $e');
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Show info snackbar
  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Network connection failed. Check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Server may be busy.';
    } else if (error.toString().contains('404')) {
      return 'File not found on server.';
    } else if (error.toString().contains('403')) {
      return 'Access denied. You may not have permission to access this file.';
    } else if (error.toString().contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return error.toString().length > 100
          ? 'An unexpected error occurred'
          : error.toString();
    }
  }

  // Ensure _verifyFileUrl is defined
  Future<bool> _verifyFileUrl(String url) async {
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Build file summary widget
  Widget _buildFileSummary(BuildContext context, bool isDark) {
    if (message.attachments.isEmpty) return const SizedBox.shrink();

    final fileCount = message.attachments.length;
    final totalSize = _getTotalFileSize(message.attachments);
    final fileTypes = _getFileTypes(message.attachments);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withOpacity(0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 14,
            color: isMe
                ? Colors.white.withOpacity(0.7)
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$fileCount file${fileCount > 1 ? 's' : ''} • $totalSize${fileTypes.isNotEmpty ? ' • $fileTypes' : ''}',
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Get total file size
  String _getTotalFileSize(List<MessageAttachment> attachments) {
    int totalSize = attachments.fold(
      0,
      (sum, attachment) => sum + (attachment.size ?? 0),
    );
    return _formatFileSize(totalSize);
  }

  // Get file types summary
  String _getFileTypes(List<MessageAttachment> attachments) {
    final typeCount = <String, int>{};

    for (final attachment in attachments) {
      final category = attachment.fileCategory;
      typeCount[category] = (typeCount[category] ?? 0) + 1;
    }

    final types = typeCount.entries
        .map(
          (entry) =>
              entry.value > 1 ? '${entry.value} ${entry.key}s' : entry.key,
        )
        .take(2) // Show max 2 types
        .join(', ');

    return types;
  }
}
