import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/models/message_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/datasources/auth_api_service.dart';
import '../../../chat/presentation/providers/conversation_provider.dart';
import '../../../chat/presentation/providers/message_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  String _themeMode = 'system';
  final AuthApiService _authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _notificationsEnabled = StorageService.getNotificationsEnabled();
    _soundEnabled = StorageService.getSoundEnabled();
    _themeMode = StorageService.getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications Section
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive notifications for new messages',
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    await StorageService.setNotificationsEnabled(value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _soundEnabled = value;
                    });
                    await StorageService.setSoundEnabled(value);
                  },
                ),
              ],
            ),

            // Appearance Section
            _buildSection(
              title: 'Appearance',
              children: [
                _buildRadioListSection(
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  groupValue: _themeMode,
                  options: [
                    {
                      'value': 'light',
                      'title': 'Light',
                      'subtitle': 'Light theme',
                    },
                    {
                      'value': 'dark',
                      'title': 'Dark',
                      'subtitle': 'Dark theme',
                    },
                    {
                      'value': 'system',
                      'title': 'System',
                      'subtitle': 'Follow system theme',
                    },
                  ],
                  onChanged: _handleThemeChange,
                ),
              ],
            ),

            // Privacy & Security Section
            _buildSection(
              title: 'Privacy & Security',
              children: [
                _buildListTile(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  icon: Icons.lock_outline,
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),

            // Data & Storage Section
            _buildSection(
              title: 'Data & Storage',
              children: [
                _buildListTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  icon: Icons.cleaning_services_outlined,
                  onTap: _clearCache,
                ),
                _buildListTile(
                  title: 'Export Data',
                  subtitle: 'Download your chat history',
                  icon: Icons.download_outlined,
                  onTap: _showExportDialog,
                ),
                _buildListTile(
                  title: 'Storage Usage',
                  subtitle: 'See how much storage you\'re using',
                  icon: Icons.storage_outlined,
                  onTap: _showStorageInfo,
                ),
              ],
            ),

            // About Section
            _buildSection(
              title: 'About',
              children: [
                _buildListTile(
                  title: 'Version',
                  subtitle: '1.0.0+1',
                  icon: Icons.info_outline,
                  onTap: null,
                ),
                _buildListTile(
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  icon: Icons.description_outlined,
                  onTap: _showTermsOfService,
                ),
                _buildListTile(
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  icon: Icons.policy_outlined,
                  onTap: _showPrivacyPolicy,
                ),
              ],
            ),

            // Account Section
            _buildSection(
              title: 'Account',
              children: [
                _buildListTile(
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout_outlined,
                  textColor: Colors.red,
                  onTap: _showLogoutDialog,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildRadioListSection({
    required String title,
    required String subtitle,
    required String groupValue,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return ExpansionTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(title),
      subtitle: Text(subtitle),
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option['title']!),
          subtitle: Text(option['subtitle']!),
          value: option['value']!,
          groupValue: groupValue,
          onChanged: (value) => onChanged(value!),
          activeColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                helperText: 'Must be at least 6 characters',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _changePassword(
              context,
              currentPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    try {
      await StorageService.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    }
  }

  void _showStorageInfo() async {
    final info = await StorageService.getDatabaseInfo();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Storage Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User data: ${info['user_box_length']} items'),
              Text('Chats: ${info['chat_box_length']} items'),
              Text('Messages: ${info['message_box_length']} items'),
              Text('Settings: ${info['settings_box_length']} items'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    // Validate inputs
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters'),
        ),
      );
      return;
    }

    // Close the dialog
    Navigator.pop(context);

    // Show loading
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Changing password...')));

    try {
      await _authApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ADRDE Chat Privacy Policy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: ${DateTime.now().year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Information We Collect\n\n'
                'We collect information you provide directly to us, such as when you create an account, send messages, or contact us for support.\n\n'
                '2. How We Use Your Information\n\n'
                'We use the information we collect to provide, maintain, and improve our services, including to facilitate secure communication between users.\n\n'
                '3. Information Sharing\n\n'
                'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.\n\n'
                '4. Data Security\n\n'
                'We implement security measures to protect your messages and personal information. Your data is secured both in transit and at rest.\n\n'
                '5. Your Rights\n\n'
                'You have the right to access, update, or delete your personal information at any time through your account settings.\n\n'
                '6. Contact Us\n\n'
                'If you have any questions about this privacy policy, please contact us at support@adrde.com.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _launchUrl('https://adrde.com/privacy'),
            child: const Text('View Online'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ADRDE Chat Terms of Service',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: ${DateTime.now().year}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Acceptance of Terms\n\n'
                'By using ADRDE Chat, you agree to be bound by these Terms of Service.\n\n'
                '2. Description of Service\n\n'
                'ADRDE Chat is a secure messaging application that provides end-to-end encrypted communication.\n\n'
                '3. User Responsibilities\n\n'
                'You are responsible for maintaining the security of your account and for all activities that occur under your account.\n\n'
                '4. Prohibited Uses\n\n'
                'You may not use our service for any illegal or unauthorized purpose or engage in any activity that interferes with or disrupts the service.\n\n'
                '5. Privacy\n\n'
                'Your privacy is important to us. Please review our Privacy Policy to understand how we collect and use your information.\n\n'
                '6. Limitation of Liability\n\n'
                'In no event shall ADRDE be liable for any indirect, incidental, special, consequential, or punitive damages.\n\n'
                '7. Changes to Terms\n\n'
                'We reserve the right to modify these terms at any time. Users will be notified of any changes.\n\n'
                '8. Contact Information\n\n'
                'For questions about these Terms of Service, please contact us at legal@adrde.com.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => _launchUrl('https://adrde.com/terms'),
            child: const Text('View Online'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _handleThemeChange(String? value) async {
    if (value != null) {
      setState(() {
        _themeMode = value;
      });

      // Update the app theme
      ThemeMode newThemeMode = ThemeMode.system;
      switch (value) {
        case 'light':
          newThemeMode = ThemeMode.light;
          break;
        case 'dark':
          newThemeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          newThemeMode = ThemeMode.system;
          break;
      }

      // Update app theme and save to storage
      await AppTheme.setTheme(newThemeMode);

      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to ${value.toUpperCase()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Chat Data'),
        content: const Text(
          'Choose the format for your chat export. This will include all your conversations and messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData('json');
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData('html');
            },
            child: const Text('HTML'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData('txt');
            },
            child: const Text('Text'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String format) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing export...'),
            ],
          ),
        ),
      );

      // Get current user
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Get conversations
      final conversationState = ref.read(conversationProvider);
      final conversations = conversationState.conversations;

      // Get messages for each conversation
      final messageState = ref.read(messageProvider);
      final conversationMessages = <String, List<MessageModel>>{};
      for (final conversation in conversations) {
        final messages = messageState.messagesByChat[conversation.id] ?? [];
        conversationMessages[conversation.id] = messages;
      }

      // Generate export file
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filename = 'chat_export_$timestamp.$format';

      late final Uint8List bytes;

      switch (format) {
        case 'json':
          bytes = await ExportService.exportAsJson(
            conversations: conversations,
            conversationMessages: conversationMessages,
            currentUser: currentUser,
          );
          break;
        case 'html':
          bytes = await ExportService.exportAsHtml(
            conversations: conversations,
            conversationMessages: conversationMessages,
            currentUser: currentUser,
          );
          break;
        case 'txt':
          bytes = await ExportService.exportAsText(
            conversations: conversations,
            conversationMessages: conversationMessages,
            currentUser: currentUser,
          );
          break;
        default:
          throw Exception('Unsupported format: $format');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // For now, show the data in a dialog (can be enhanced for actual download)
      await _showExportResult(bytes, filename, format);
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showExportResult(
    dynamic bytes,
    String filename,
    String format,
  ) async {
    final size = bytes.length;
    final sizeText = size < 1024
        ? '${size}B'
        : size < 1024 * 1024 * 1024 * 1024 * 1024 * 1024
        ? '${(size / 1024).toStringAsFixed(1)}KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $filename'),
            Text('Size: $sizeText'),
            Text('Format: ${format.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text(
              'Your chat data has been prepared for export. In a full implementation, this would be downloaded to your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (format == 'json' || format == 'txt')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showExportPreview(bytes, format);
              },
              child: const Text('Preview'),
            ),
        ],
      ),
    );
  }

  void _showExportPreview(dynamic bytes, String format) {
    final content = String.fromCharCodes(bytes);
    final preview = content.length > 1000
        ? '${content.substring(0, 1000)}...\n\n[Content truncated for display]'
        : content;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Preview (${format.toUpperCase()})'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SelectableText(
              preview,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
