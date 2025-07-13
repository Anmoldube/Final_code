import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/connectivity_status.dart';

class MessageInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String, {List<String>? attachments}) onSendMessage;
  final ValueChanged<bool>? onTyping;
  final VoidCallback? onFilePick;
  final VoidCallback? onImagePick;
  final String? hintText;
  final bool enabled;
  final int maxLines;
  final bool hasSelectedFiles;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.onTyping,
    this.onFilePick,
    this.onImagePick,
    this.hintText,
    this.enabled = true,
    this.maxLines = 5,
    this.hasSelectedFiles = false,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  late FocusNode _focusNode;
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isTyping = hasText;

    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      widget.onTyping?.call(isTyping);
    }
  }

  void _sendMessage() {
    final content = widget.controller.text.trim();
    if (content.isNotEmpty || widget.hasSelectedFiles) {
      widget.onSendMessage(content);

      // Clear the text field after sending
      widget.controller.clear();

      // Keep the focus on the input field for continuous typing
      // Use multiple strategies to ensure focus is maintained
      _focusNode.requestFocus();

      // Also add a microtask to handle cases where focus might be lost during UI updates
      Future.microtask(() {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOffline = ref.watch(isOfflineProvider);

    // Show offline indicator in the input field
    final hintText = isOffline
        ? 'You are offline. Messages will be sent when you reconnect.'
        : widget.hintText ?? 'Type a message...';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkDividerColor.withOpacity(0.3)
                : AppTheme.lightDividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show offline indicator if needed
            if (isOffline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Offline mode: Messages will be saved locally and sent when you reconnect',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                _buildAttachmentButton(isDark),

                const SizedBox(width: 12),

                // Text input
                Expanded(child: _buildTextInput(isDark, hintText: hintText)),

                const SizedBox(width: 12),

                // Send button
                _buildSendButton(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(bool isDark) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.attach_file,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      onSelected: _handleAttachmentSelection,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt),
              SizedBox(width: 12),
              Text('Camera'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library),
              SizedBox(width: 12),
              Text('Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'file',
          child: Row(
            children: [
              Icon(Icons.insert_drive_file),
              SizedBox(width: 12),
              Text('File'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'document',
          child: Row(
            children: [
              Icon(Icons.description),
              SizedBox(width: 12),
              Text('Document'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(bool isDark, {String? hintText}) {
    final isOffline = ref.watch(isOfflineProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            widget.maxLines * 24.0 + 32, // Approximate line height + padding
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isOffline
              ? AppTheme.warningColor.withOpacity(0.5)
              : (isDark
                    ? AppTheme.darkDividerColor.withOpacity(0.3)
                    : AppTheme.lightDividerColor.withOpacity(0.3)),
          width: isOffline ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: null,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        decoration: InputDecoration(
          hintText: hintText ?? widget.hintText ?? 'Type a message...',
          hintStyle: TextStyle(
            color: isOffline
                ? AppTheme.warningColor
                : (isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
            fontStyle: isOffline ? FontStyle.italic : FontStyle.normal,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontSize: 16,
          height: 1.4,
        ),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildSendButton(bool isDark) {
    final canSend = _hasText || widget.hasSelectedFiles;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: canSend ? AppTheme.primaryColor : Colors.grey[400],
        shape: BoxShape.circle,
        boxShadow: canSend
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSend ? _sendMessage : null,
          borderRadius: BorderRadius.circular(24),
          child: Icon(
            canSend ? Icons.send_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _handleAttachmentSelection(String type) {
    switch (type) {
      case 'camera':
        widget.onImagePick?.call();
        break;
      case 'gallery':
        widget.onImagePick?.call();
        break;
      case 'file':
      case 'document':
        widget.onFilePick?.call();
        break;
    }
  }
}

// Extended message input with reply and edit functionality
class ExtendedMessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String, {List<String>? attachments}) onSendMessage;
  final ValueChanged<bool>? onTyping;
  final VoidCallback? onFilePick;
  final VoidCallback? onImagePick;
  final dynamic replyToMessage;
  final VoidCallback? onCancelReply;
  final dynamic editingMessage;
  final VoidCallback? onCancelEdit;
  final String? hintText;
  final bool enabled;

  const ExtendedMessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.onTyping,
    this.onFilePick,
    this.onImagePick,
    this.replyToMessage,
    this.onCancelReply,
    this.editingMessage,
    this.onCancelEdit,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<ExtendedMessageInput> createState() => _ExtendedMessageInputState();
}

class _ExtendedMessageInputState extends State<ExtendedMessageInput> {
  late FocusNode _focusNode;
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isTyping = hasText;

    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      widget.onTyping?.call(isTyping);
    }
  }

  void _sendMessage() {
    final content = widget.controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSendMessage(content);

      // Clear the text field after sending
      widget.controller.clear();

      // Keep the focus on the input field for continuous typing
      // Use multiple strategies to ensure focus is maintained
      _focusNode.requestFocus();

      // Also add a microtask to handle cases where focus might be lost during UI updates
      Future.microtask(() {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Reply/Edit bar
        if (widget.replyToMessage != null) ...[_buildReplyBar(isDark)],
        if (widget.editingMessage != null) ...[_buildEditBar(isDark)],

        // Main input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppTheme.darkDividerColor
                    : AppTheme.lightDividerColor,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                _buildAttachmentButton(isDark),

                const SizedBox(width: 8),

                // Text input
                Expanded(child: _buildTextInput(isDark)),

                const SizedBox(width: 8),

                // Send button
                _buildSendButton(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkDividerColor
                : AppTheme.lightDividerColor,
          ),
          left: BorderSide(color: AppTheme.primaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${widget.replyToMessage?.sender?.displayName ?? 'Unknown'}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.replyToMessage?.content ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildEditBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppTheme.darkDividerColor
                : AppTheme.lightDividerColor,
          ),
          left: BorderSide(color: Colors.orange, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing message',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(bool isDark) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.attach_file,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      onSelected: _handleAttachmentSelection,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              Icon(Icons.camera_alt),
              SizedBox(width: 12),
              Text('Camera'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              Icon(Icons.photo_library),
              SizedBox(width: 12),
              Text('Gallery'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'file',
          child: Row(
            children: [
              Icon(Icons.insert_drive_file),
              SizedBox(width: 12),
              Text('File'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(bool isDark) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 120, // About 5 lines
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDividerColor
              : AppTheme.lightDividerColor,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: null,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _sendMessage(),
        decoration: InputDecoration(
          hintText:
              widget.hintText ??
              (widget.editingMessage != null
                  ? 'Edit message...'
                  : 'Type a message...'),
          hintStyle: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontSize: 16,
        ),
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildSendButton(bool isDark) {
    return GestureDetector(
      onTap: _hasText ? _sendMessage : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _hasText
              ? (widget.editingMessage != null
                    ? Colors.orange
                    : AppTheme.primaryColor)
              : Colors.grey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.editingMessage != null
              ? Icons.check
              : (_hasText ? Icons.send : Icons.mic),
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _handleAttachmentSelection(String type) {
    switch (type) {
      case 'camera':
      case 'gallery':
        widget.onImagePick?.call();
        break;
      case 'file':
        widget.onFilePick?.call();
        break;
    }
  }
}
