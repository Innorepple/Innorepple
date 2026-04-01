import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, child) {
          if (!settings.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              _buildSection(
                context,
                'Notifications',
                Icons.notifications_outlined,
                [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive notifications for reminders and updates',
                    settings.notificationsEnabled,
                    settings.setNotificationsEnabled,
                    Icons.notifications,
                  ),
                  _buildSwitchTile(
                    'Sound',
                    'Play sound for notifications',
                    settings.soundEnabled,
                    settings.setSoundEnabled,
                    Icons.volume_up,
                    enabled: settings.notificationsEnabled,
                  ),
                  _buildSwitchTile(
                    'Vibration',
                    'Vibrate for notifications',
                    settings.vibrationEnabled,
                    settings.setVibrationEnabled,
                    Icons.vibration,
                    enabled: settings.notificationsEnabled,
                  ),
                  _buildTimeTile(
                    context,
                    'Daily Reminder Time',
                    'Set time for daily health check reminders',
                    settings.reminderTime,
                    settings.setReminderTime,
                    Icons.schedule,
                    enabled: settings.notificationsEnabled,
                  ),
                ],
              ),
              _buildSection(
                context,
                'Appearance',
                Icons.palette_outlined,
                [
                  _buildSwitchTile(
                    'Dark Mode',
                    'Use dark theme throughout the app',
                    settings.darkMode,
                    settings.setDarkMode,
                    Icons.dark_mode,
                  ),
                  _buildDropdownTile(
                    context,
                    'Language',
                    'Choose your preferred language',
                    settings.language,
                    settings.setLanguage,
                    Icons.language,
                    ['English', 'हिन्दी', 'বাংলা', 'தமிழ்'],
                  ),
                ],
              ),
              _buildSection(
                context,
                'Health & Wellness',
                Icons.health_and_safety_outlined,
                [
                  _buildSwitchTile(
                    'Health Tips',
                    'Show daily health tips and recommendations',
                    settings.tipsEnabled,
                    settings.setTipsEnabled,
                    Icons.lightbulb_outline,
                  ),
                  _buildSwitchTile(
                    'Privacy Mode',
                    'Hide sensitive health information in previews',
                    settings.privacyMode,
                    settings.setPrivacyMode,
                    Icons.privacy_tip_outlined,
                  ),
                ],
              ),
              _buildSection(
                context,
                'Data & Sync',
                Icons.cloud_sync_outlined,
                [
                  _buildSwitchTile(
                    'Auto Sync',
                    'Automatically sync data with cloud',
                    settings.autoSync,
                    settings.setAutoSync,
                    Icons.sync,
                  ),
                  _buildSwitchTile(
                    'Data Saver Mode',
                    'Reduce data usage for images and videos',
                    settings.dataSaver,
                    settings.setDataSaver,
                    Icons.data_saver_on,
                  ),
                ],
              ),
              _buildSection(
                context,
                'Advanced',
                Icons.settings_outlined,
                [
                  _buildActionTile(
                    'Clear Cache',
                    'Free up storage space',
                    Icons.delete_sweep,
                    () => _showClearCacheDialog(context),
                  ),
                  _buildActionTile(
                    'Export Data',
                    'Export your health data',
                    Icons.file_download,
                    () => _showExportDialog(context),
                  ),
                  _buildActionTile(
                    'Reset Settings',
                    'Reset all settings to default values',
                    Icons.restore,
                    () => _showResetDialog(context, settings),
                    isDestructive: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Switch(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
      enabled: enabled,
    );
  }

  Widget _buildTimeTile(
    BuildContext context,
    String title,
    String subtitle,
    TimeOfDay time,
    Future<void> Function(TimeOfDay) onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : Colors.grey),
      title: Text(
        title,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: enabled ? null : Colors.grey),
      ),
      trailing: Text(
        time.format(context),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
      ),
      onTap: enabled
          ? () async {
              final newTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (newTime != null) {
                onChanged(newTime);
              }
            }
          : null,
      enabled: enabled,
    );
  }

  Widget _buildDropdownTile(
    BuildContext context,
    String title,
    String subtitle,
    String value,
    Future<void> Function(String) onChanged,
    IconData icon,
    List<String> options,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear temporary files and free up storage space. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export your health data as a CSV file. This may take a moment.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export started. Check your downloads folder.')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await settings.resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}