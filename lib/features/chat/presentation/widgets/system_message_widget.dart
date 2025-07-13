import 'package:flutter/material.dart';
import '../../../../core/models/message_model.dart';
import '../utils/system_message_helper.dart';

class SystemMessageWidget extends StatelessWidget {
  final MessageModel message;

  const SystemMessageWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Don't show system messages in the chat flow for now
    // This can be enabled later if needed
    if (SystemMessageHelper.isSystemMessage(message)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.grey[800]?.withOpacity(0.5)
                : Colors.grey[200]?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
