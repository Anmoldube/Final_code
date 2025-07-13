import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/presence_model.dart';
import '../../../../core/services/simple_presence_service.dart';
import '../../../../core/widgets/simple_presence_indicator.dart';

class SimplePresenceSettingsWidget extends StatefulWidget {
  final bool isEditing;

  const SimplePresenceSettingsWidget({super.key, required this.isEditing});

  @override
  State<SimplePresenceSettingsWidget> createState() =>
      _SimplePresenceSettingsWidgetState();
}

class _SimplePresenceSettingsWidgetState
    extends State<SimplePresenceSettingsWidget> {
  late PresenceSettings _tempSettings;
  bool _hasChanges = false;
  UserPresence? _currentPresence;

  @override
  void initState() {
    super.initState();
    final service = SimplePresenceService.instance;
    _tempSettings = service.presenceSettings;
    _currentPresence = service.currentUserPresence;

    // Listen to presence updates
    service.currentUserPresenceStream.listen((presence) {
      if (mounted) {
        setState(() {
          _currentPresence = presence;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          if (_currentPresence != null) ...[
            _buildCurrentStatusPreview(_currentPresence!, context),
            const SizedBox(height: 20),
          ],

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
    UserPresence presence,
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
          SimplePresenceIndicator(
            state: presence.state,
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
                  '${presence.state.emoji} ${presence.state.displayName}',
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

  Widget _buildSettingsOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show Last Seen
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
                _tempSettings = SimplePresenceService.instance.presenceSettings;
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
              await SimplePresenceService.instance.updatePresenceSettings(
                _tempSettings,
              );
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
}
