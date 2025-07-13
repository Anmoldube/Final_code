import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_status.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class StatusSelector extends ConsumerStatefulWidget {
  final UserStatus currentStatus;
  final Function(UserStatus status, String? customMessage)? onStatusChanged;
  final bool showCustomMessage;

  const StatusSelector({
    super.key,
    required this.currentStatus,
    this.onStatusChanged,
    this.showCustomMessage = true,
  });

  @override
  ConsumerState<StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends ConsumerState<StatusSelector> {
  final TextEditingController _customMessageController =
      TextEditingController();
  UserStatus? _selectedStatus;
  bool _showCustomMessage = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _showCustomMessage = widget.showCustomMessage;
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 420,
      constraints: const BoxConstraints(maxHeight: 600),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.currentStatus.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.circle,
                  color: widget.currentStatus.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Choose how others see your availability',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick status options
          _buildQuickStatusOptions(),

          const SizedBox(height: 20),

          // All status options
          _buildAllStatusOptions(),

          if (_showCustomMessage) ...[
            const SizedBox(height: 20),
            _buildCustomMessageField(),
          ],

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickStatusOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick options',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: UserStatus.quickStatuses.map((status) {
            final isSelected = _selectedStatus == status;
            return InkWell(
              onTap: () => _selectStatus(status),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? status.color.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? status.color
                        : Theme.of(context).dividerColor.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    status.toWidget(size: 12),
                    const SizedBox(width: 8),
                    Text(
                      status.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? status.color : null,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllStatusOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All options',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: UserStatus.selectableStatuses.map((status) {
                final isSelected = _selectedStatus == status;
                return InkWell(
                  onTap: () => _selectStatus(status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? status.color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: status.toWidget(size: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.displayName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected ? status.color : null,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.getTimeBasedMessage(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected) ...[
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: status.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom message (optional)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customMessageController,
          decoration: InputDecoration(
            hintText: 'What\'s your status?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBackground
                : Colors.grey.shade50,
          ),
          maxLength: 100,
          maxLines: 2,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedStatus != null ? _applyStatus : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedStatus?.color ?? AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, size: 16),
                const SizedBox(width: 8),
                const Text('Apply Status'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectStatus(UserStatus status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _applyStatus() {
    if (_selectedStatus != null) {
      final customMessage = _customMessageController.text.trim();
      widget.onStatusChanged?.call(
        _selectedStatus!,
        customMessage.isNotEmpty ? customMessage : null,
      );

      // Update the status in the auth provider
      ref
          .read(authProvider.notifier)
          .updateUserStatus(
            _selectedStatus!,
            customMessage.isNotEmpty ? customMessage : null,
          );
    }
    Navigator.pop(context);
  }
}

// Status indicator widget for use in other places
class StatusIndicatorWidget extends StatelessWidget {
  final UserStatus status;
  final String? customMessage;
  final double size;
  final bool showLabel;
  final bool showMessage;

  const StatusIndicatorWidget({
    super.key,
    required this.status,
    this.customMessage,
    this.size = 12,
    this.showLabel = false,
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        status.toWidget(size: size),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (showMessage && customMessage != null) ...[
          const SizedBox(width: 6),
          Text(
            customMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// Helper function to show status selector
Future<void> showStatusSelector(
  BuildContext context, {
  required UserStatus currentStatus,
  Function(UserStatus status, String? customMessage)? onStatusChanged,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: StatusSelector(
        currentStatus: currentStatus,
        onStatusChanged: onStatusChanged,
      ),
    ),
  );
}
