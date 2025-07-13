import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/timestamp_service.dart';

class MessageStatusWidget extends StatefulWidget {
  final MessageModel message;
  final bool isOwnMessage;
  final VoidCallback? onRetry;

  const MessageStatusWidget({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onRetry,
  });

  @override
  State<MessageStatusWidget> createState() => _MessageStatusWidgetState();
}

class _MessageStatusWidgetState extends State<MessageStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _tickAnimationController;
  late AnimationController _clockAnimationController;
  late Animation<double> _tickAnimation;
  late Animation<double> _clockAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for tick marks
    _tickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animation for clock icon
    _clockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tickAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _clockAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _clockAnimationController, curve: Curves.linear),
    );

    _startAnimations();
  }

  void _startAnimations() {
    final status = widget.message.displayStatus;

    if (status.showClock) {
      _clockAnimationController.repeat();
    } else {
      _clockAnimationController.stop();
      if (status.isSuccessful) {
        _tickAnimationController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(MessageStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.status != widget.message.status) {
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _tickAnimationController.dispose();
    _clockAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show status for own messages
    if (!widget.isOwnMessage) {
      return const SizedBox.shrink();
    }

    final status = widget.message.displayStatus;
    final theme = Theme.of(context);

    // Debug logging
    debugPrint(
      '🎯 MessageStatusWidget: Message ${widget.message.id} status: $status, readBy: ${widget.message.readBy}',
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timestamp
        Text(
          _formatTime(widget.message.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),

        // Status Icon
        _buildStatusIcon(status, theme),

        // Retry button for failed messages
        if (status.canRetry && widget.onRetry != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onRetry,
            child: Icon(
              Icons.refresh,
              size: 14,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(MessageStatus status, ThemeData theme) {
    switch (status) {
      case MessageStatus.pending:
      case MessageStatus.sending:
        return AnimatedBuilder(
          animation: _clockAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _clockAnimation.value * 2 * 3.14159,
              child: Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            );
          },
        );

      case MessageStatus.sent:
        return AnimatedBuilder(
          animation: _tickAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _tickAnimation.value,
              child: Icon(
                Icons.check,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            );
          },
        );

      case MessageStatus.delivered:
        return AnimatedBuilder(
          animation: _tickAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _tickAnimation.value,
              child: Stack(
                children: [
                  Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  Positioned(
                    left: 3,
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case MessageStatus.read:
        return AnimatedBuilder(
          animation: _tickAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _tickAnimation.value,
              child: Stack(
                children: [
                  Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.green, // <-- Try green for visibility
                  ),
                  Positioned(
                    left: 3,
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green, // <-- Try green for visibility
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case MessageStatus.failed:
        return Tooltip(
          message: widget.message.failureReason ?? 'Failed to send',
          child: Icon(
            Icons.error_outline,
            size: 14,
            color: theme.colorScheme.error,
          ),
        );
    }
  }

  String _formatTime(DateTime dateTime) {
    final validatedTime = TimestampService.validateTimestamp(dateTime);
    final localTime = validatedTime.toLocal();
    final now = TimestampService.getCurrentTimestamp();
    final difference = now.difference(localTime);

    if (difference.inDays > 0) {
      // Show date and time for messages older than a day
      return DateFormat('d MMM, h:mm a').format(localTime);
    } else if (difference.inMinutes > 0) {
      // Show time in AM/PM format for today's messages
      return DateFormat('h:mm a').format(localTime);
    } else {
      return 'now';
    }
  }
}

/// Enhanced Message Status Widget with detailed information
class DetailedMessageStatusWidget extends StatelessWidget {
  final MessageModel message;
  final bool showDetails;

  const DetailedMessageStatusWidget({
    super.key,
    required this.message,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDetails) {
      return MessageStatusWidget(message: message, isOwnMessage: true);
    }

    final theme = Theme.of(context);
    final status = message.displayStatus;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status header
          Row(
            children: [
              _getStatusIcon(status, theme),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Timestamps
          if (message.sentAt != null)
            _buildTimestampRow('Sent', message.sentAt!, theme),

          if (message.deliveredAt != null)
            _buildTimestampRow('Delivered', message.deliveredAt!, theme),

          if (message.readAt != null)
            _buildTimestampRow('Read', message.readAt!, theme),

          // Read by information for group chats
          if (message.readBy != null && message.readBy!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Read by: ${message.readBy!.length} recipient(s)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],

          // Retry information
          if (message.retryCount != null && message.retryCount! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Retry attempts: ${message.retryCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],

          // Failure reason
          if (message.failureReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error: ${message.failureReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime timestamp, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            _formatDetailedTime(timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(MessageStatus status, ThemeData theme) {
    switch (status) {
      case MessageStatus.pending:
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        );
      case MessageStatus.delivered:
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            Positioned(
              left: 4,
              child: Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        );
      case MessageStatus.read:
        return Stack(
          children: [
            Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
            Positioned(
              left: 4,
              child: Icon(Icons.check, size: 16, color: Colors.green),
            ),
          ],
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: theme.colorScheme.error,
        );
    }
  }

  String _formatDetailedTime(DateTime dateTime) {
    final validatedTime = TimestampService.validateTimestamp(dateTime);
    final now = TimestampService.getCurrentTimestamp();
    final difference = now.difference(validatedTime);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy HH:mm').format(validatedTime);
    } else {
      return DateFormat('HH:mm:ss').format(validatedTime);
    }
  }
}
