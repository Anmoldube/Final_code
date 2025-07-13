import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/presence_model.dart' as presence_model;
import '../../../../core/providers/presence_provider.dart';
import '../../../../core/widgets/presence_indicator.dart';

class PresenceSettingsWidget extends ConsumerStatefulWidget {
  final bool isEditing;

  const PresenceSettingsWidget({super.key, required this.isEditing});

  @override
  ConsumerState<PresenceSettingsWidget> createState() =>
      _PresenceSettingsState();
}

class _PresenceSettingsState extends ConsumerState<PresenceSettingsWidget> {
  late presence_model.PresenceSettings _tempSettings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tempSettings = ref.read(presenceSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(presenceSettingsProvider);
    final currentUserPresence = ref.watch(currentUserPresenceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Update temp settings when provider changes
    if (!_hasChanges) {
      _tempSettings = settings;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.visibility, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Presence & Privacy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current status preview
          if (currentUserPresence != null) ...[
            _buildCurrentStatusPreview(currentUserPresence, context),
            const SizedBox(height: 20),
          ],

          // Custom status section
          _buildCustomStatusSection(),

          const SizedBox(height: 20),

          // Settings options
          _buildSettingsOptions(),

          if (widget.isEditing && _hasChanges) ...[
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStatusPreview(
    presence_model.UserPresence presence,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: presence.state.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: presence.state.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          PresenceIndicator(
            userId: presence.userId,
            size: 16,
            showBorder: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your current status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  presence.getStatusText(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: presence.state.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStatusSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserPresence = ref.watch(currentUserPresenceProvider);

    // Predefined custom statuses similar to Slack
    final customStatuses = [
      {'text': 'In a meeting', 'emoji': '📅', 'duration': '1 hour'},
      {'text': 'On lunch', 'emoji': '🍽️', 'duration': '30 minutes'},
      {'text': 'Working remotely', 'emoji': '🏠', 'duration': 'Today'},
      {'text': 'In focus time', 'emoji': '🎯', 'duration': '2 hours'},
      {'text': 'On a call', 'emoji': '📞', 'duration': '30 minutes'},
      {'text': 'Be right back', 'emoji': '⏰', 'duration': '15 minutes'},
      {'text': 'Out sick', 'emoji': '🤒', 'duration': 'Today'},
      {'text': 'On vacation', 'emoji': '🏖️', 'duration': 'This week'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.edit_note, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Custom Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current custom status display
          if (currentUserPresence?.customStatus != null &&
              currentUserPresence!.customStatus!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text('💬', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentUserPresence.customStatus!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    IconButton(
                      onPressed: () => _clearCustomStatus(),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      tooltip: 'Clear status',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Quick status options
          if (widget.isEditing) ...[
            Text(
              'Quick options',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customStatuses.map((status) {
                return InkWell(
                  onTap: () => _setCustomStatus(status['text']!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status['emoji']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status['text']!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Custom status input
            TextField(
              decoration: InputDecoration(
                hintText: 'Set a custom status...',
                prefixIcon: const Icon(Icons.edit_note, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkBackground
                    : Colors.grey.shade50,
              ),
              maxLength: 100,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _setCustomStatus(value.trim());
                }
              },
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            // View mode - show instruction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enable editing to set custom status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Online Status Visibility
        _buildSettingsTile(
          title: 'Show Online Status',
          subtitle: 'Others can see when you\'re online',
          value: _tempSettings.showOnlineStatus,
          onChanged: widget.isEditing
              ? (value) {
                  setState(() {
                    _tempSettings = _tempSettings.copyWith(
                      showOnlineStatus: value,
                    );
                    _hasChanges = true;
                  });
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Last Seen Visibility
        _buildSettingsTile(
          title: 'Show Last Seen',
          subtitle: 'Others can see when you were last online',
          value: _tempSettings.showLastSeen,
          onChanged: widget.isEditing
              ? (value) {
                  setState(() {
                    _tempSettings = _tempSettings.copyWith(showLastSeen: value);
                    _hasChanges = true;
                  });
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Idle Detection
        _buildSettingsTile(
          title: 'Auto-Away Detection',
          subtitle: 'Automatically set status to away when idle',
          value: _tempSettings.enableIdleDetection,
          onChanged: widget.isEditing
              ? (value) {
                  setState(() {
                    _tempSettings = _tempSettings.copyWith(
                      enableIdleDetection: value,
                    );
                    _hasChanges = true;
                  });
                }
              : null,
        ),

        if (_tempSettings.enableIdleDetection) ...[
          const SizedBox(height: 12),
          _buildIdleTimeoutSlider(),
        ],

        const SizedBox(height: 12),

        // Always Show Online
        _buildSettingsTile(
          title: 'Always Show Online',
          subtitle: 'Always appear online regardless of activity',
          value: _tempSettings.alwaysShowOnline,
          onChanged: widget.isEditing
              ? (value) {
                  setState(() {
                    _tempSettings = _tempSettings.copyWith(
                      alwaysShowOnline: value,
                    );
                    _hasChanges = true;
                  });
                }
              : null,
        ),

        const SizedBox(height: 12),

        // Appear Offline
        _buildSettingsTile(
          title: 'Appear Offline',
          subtitle: 'Hide your presence from others',
          value: _tempSettings.appearOffline,
          onChanged: widget.isEditing
              ? (value) {
                  setState(() {
                    _tempSettings = _tempSettings.copyWith(
                      appearOffline: value,
                    );
                    _hasChanges = true;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildIdleTimeoutSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Idle timeout',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              '${_tempSettings.idleTimeoutMinutes} minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
          ),
          child: Slider(
            value: _tempSettings.idleTimeoutMinutes.toDouble(),
            min: 1,
            max: 60,
            divisions: 59,
            onChanged: widget.isEditing
                ? (value) {
                    setState(() {
                      _tempSettings = _tempSettings.copyWith(
                        idleTimeoutMinutes: value.round(),
                      );
                      _hasChanges = true;
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _tempSettings = ref.read(presenceSettingsProvider);
                _hasChanges = false;
              });
            },
            child: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await ref
                  .read(presenceProvider.notifier)
                  .updatePresenceSettings(_tempSettings);
              setState(() {
                _hasChanges = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Presence settings updated successfully'),
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  void _setCustomStatus(String status) async {
    try {
      await ref
          .read(presenceProvider.notifier)
          .setUserStatus(
            presence_model.PresenceState.online,
            customStatus: status,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status set to: $status'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCustomStatus() async {
    try {
      await ref
          .read(presenceProvider.notifier)
          .setUserStatus(
            presence_model.PresenceState.online,
            customStatus: null,
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Custom status cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
