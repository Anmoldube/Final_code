import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  final double size;
  final bool showBorder;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusColor,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              )
            : null,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'available':
        return const Color(0xFF4CAF50); // Green
      case 'away':
        return const Color(0xFFFF9800); // Orange
      case 'busy':
      case 'do not disturb':
      case 'dnd':
        return const Color(0xFFF44336); // Red
      case 'in a meeting':
      case 'meeting':
        return const Color(0xFF9C27B0); // Purple
      case 'offline':
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  static String getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'online':
      case 'available':
        return 'Available';
      case 'away':
        return 'Away';
      case 'busy':
      case 'do not disturb':
      case 'dnd':
        return 'Do Not Disturb';
      case 'in a meeting':
      case 'meeting':
        return 'In a Meeting';
      case 'offline':
      default:
        return 'Offline';
    }
  }
}

// Animated status indicator for real-time updates
class AnimatedStatusIndicator extends StatefulWidget {
  final String status;
  final double size;
  final bool showBorder;

  const AnimatedStatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  State<AnimatedStatusIndicator> createState() =>
      _AnimatedStatusIndicatorState();
}

class _AnimatedStatusIndicatorState extends State<AnimatedStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.status.toLowerCase() == 'online' ||
        widget.status.toLowerCase() == 'available') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status.toLowerCase() == 'online' ||
          widget.status.toLowerCase() == 'available') {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: StatusIndicator(
            status: widget.status,
            size: widget.size,
            showBorder: widget.showBorder,
          ),
        );
      },
    );
  }
}

// Large status selector widget
class StatusSelector extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String>? onStatusChanged;
  final bool enabled;

  const StatusSelector({
    super.key,
    required this.selectedStatus,
    this.onStatusChanged,
    this.enabled = true,
  });

  static const List<Map<String, dynamic>> statuses = [
    {
      'value': 'available',
      'label': 'Available',
      'description': 'Ready to chat and collaborate',
      'icon': Icons.check_circle_outline,
    },
    {
      'value': 'away',
      'label': 'Away',
      'description': 'Temporarily away from desk',
      'icon': Icons.access_time,
    },
    {
      'value': 'busy',
      'label': 'Do Not Disturb',
      'description': 'Please only disturb if urgent',
      'icon': Icons.do_not_disturb_on_outlined,
    },
    {
      'value': 'meeting',
      'label': 'In a Meeting',
      'description': 'Currently in a meeting',
      'icon': Icons.people_outline,
    },
    {
      'value': 'offline',
      'label': 'Appear Offline',
      'description': 'Won\'t receive notifications',
      'icon': Icons.visibility_off_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: statuses.map((status) {
        final isSelected = selectedStatus.toLowerCase() == status['value'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            enabled: enabled,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusIndicator(status: status['value'], size: 16),
                const SizedBox(width: 12),
                Icon(
                  status['icon'],
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ],
            ),
            title: Text(
              status['label'],
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(status['description']),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : null,
            onTap: enabled
                ? () => onStatusChanged?.call(status['value'])
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// Compact status selector dropdown
class CompactStatusSelector extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String>? onStatusChanged;
  final bool enabled;

  const CompactStatusSelector({
    super.key,
    required this.selectedStatus,
    this.onStatusChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = StatusSelector.statuses.firstWhere(
      (status) => status['value'] == selectedStatus.toLowerCase(),
      orElse: () => StatusSelector.statuses.first,
    );

    return PopupMenuButton<String>(
      enabled: enabled,
      onSelected: onStatusChanged,
      itemBuilder: (context) => StatusSelector.statuses.map((status) {
        return PopupMenuItem<String>(
          value: status['value'],
          child: Row(
            children: [
              StatusIndicator(status: status['value'], size: 14),
              const SizedBox(width: 12),
              Icon(status['icon'], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status['label'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      status['description'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusIndicator(status: selectedStatus, size: 14),
            const SizedBox(width: 8),
            Text(currentStatus['label']),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
