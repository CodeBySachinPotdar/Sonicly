import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsVM = context.watch<SettingsViewModel>();
    final libraryVM = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildHeader(theme, 'APPEARANCE'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Mode'),
            subtitle: Text(settingsVM.themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: settingsVM.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) settingsVM.setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
            ),
          ),
          if (settingsVM.themeMode == ThemeMode.dark)
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('AMOLED Pure Black'),
              subtitle: const Text('Deep black background for OLED screens'),
              value: settingsVM.isAmoled,
              onChanged: (val) => settingsVM.setAmoled(val),
            ),
          const Divider(),

          _buildHeader(theme, 'PLAYBACK BEHAVIOR'),
          SwitchListTile(
            secondary: const Icon(Icons.restore_rounded),
            title: const Text('Resume Playback'),
            subtitle: const Text('Restore last playing track and position on launch'),
            value: settingsVM.resumeOnLaunch,
            onChanged: (val) => settingsVM.setResumeOnLaunch(val),
          ),
          const Divider(),

          _buildHeader(theme, 'MUSIC LIBRARY'),
          ListTile(
            leading: libraryVM.isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_time_rounded),
            title: const Text('Scan Recently Added Songs'),
            subtitle: const Text('Quickly discover songs added or modified in the last 7 days'),
            onTap: libraryVM.isScanning
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await libraryVM.scanRecentlyAddedSongs();
                    if (result != null && context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            result.newSongsAdded > 0
                                ? 'Found and added ${result.newSongsAdded} new song(s)!'
                                : 'No new songs discovered.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
          ),
          ListTile(
            leading: libraryVM.isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            title: const Text('Rescan Device Music'),
            subtitle: Text(
              libraryVM.isScanning
                  ? 'Scanning: ${libraryVM.currentScanFile}'
                  : 'Refresh songs, albums, and metadata from storage',
            ),
            onTap: libraryVM.isScanning
                ? null
                : () async {
                    await libraryVM.rescanLibrary();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Scan complete. Discovered ${libraryVM.songs.length} audio tracks.',
                          ),
                        ),
                      );
                    }
                  },
          ),
          ListTile(
            leading: const Icon(Icons.history_toggle_off_rounded),
            title: const Text('Clear Playback History'),
            subtitle: const Text('Reset play counts and recently played history'),
            onTap: () => _confirmClearHistory(context, libraryVM),
          ),
          const Divider(),

          _buildHeader(theme, 'ABOUT & PRIVACY'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LocalTune Music Player',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'All your music. One simple player.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v1.0.0 • Production Build',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('100% Offline & Private'),
            subtitle: Text('Zero telemetry, zero ads, no cloud sync, and no accounts. Your audio files never leave your device.'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'LocalTune Music Player',
                applicationVersion: '1.0.0',
                applicationLegalese: 'All your music. One simple player.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, LibraryViewModel libraryVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear your recently played and most played history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              libraryVM.clearHistory();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Playback history cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
