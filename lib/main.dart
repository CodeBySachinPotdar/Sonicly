import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_focus/audio_focus_manager.dart';
import 'audio/player_service/audio_player_handler.dart';
import 'data/repositories/music_repository_impl.dart';
import 'data/repositories/playlist_repository_impl.dart';
import 'domain/repositories/music_repository.dart';
import 'domain/repositories/playlist_repository.dart';
import 'presentation/main_navigation_shell.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/view_models/library_view_model.dart';
import 'presentation/view_models/player_view_model.dart';
import 'presentation/view_models/playlists_view_model.dart';
import 'presentation/view_models/settings_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final musicRepository = MusicRepositoryImpl();
  final playlistRepository = PlaylistRepositoryImpl();

  // Initialize AudioService for background playback & lockscreen media controls
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(musicRepository: musicRepository),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.antigravity.musicplayer.audio',
      androidNotificationChannelName: 'Music Player Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
      notificationColor: Color(0xFF6366F1),
    ),
  );

  // Initialize Audio Focus & Interruption Manager
  final audioFocusManager = AudioFocusManager(playerHandler: audioHandler);
  await audioFocusManager.init();

  // Initialize Settings
  final settingsVM = SettingsViewModel();
  await settingsVM.loadSettings();

  // Restore playback state if enabled
  if (settingsVM.resumeOnLaunch) {
    await audioHandler.restoreLastSession();
  }

  // Initialize Library and Playlists ViewModels
  final libraryVM = LibraryViewModel(musicRepository: musicRepository);
  final playlistsVM = PlaylistsViewModel(playlistRepository: playlistRepository);
  final playerVM = PlayerViewModel(
    audioHandler: audioHandler,
    musicRepository: musicRepository,
  );

  // Initial load
  await libraryVM.loadLibrary();
  await playlistsVM.loadPlaylists();

  // If library is empty on launch, prompt initial scan
  if (libraryVM.songs.isEmpty) {
    // Background scan after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      libraryVM.requestPermissionsAndScan();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<MusicRepository>.value(value: musicRepository),
        Provider<PlaylistRepository>.value(value: playlistRepository),
        Provider<AudioPlayerHandler>.value(value: audioHandler),
        ChangeNotifierProvider<SettingsViewModel>.value(value: settingsVM),
        ChangeNotifierProvider<LibraryViewModel>.value(value: libraryVM),
        ChangeNotifierProvider<PlaylistsViewModel>.value(value: playlistsVM),
        ChangeNotifierProvider<PlayerViewModel>.value(value: playerVM),
      ],
      child: const MusicPlayerApp(),
    ),
  );
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsVM = context.watch<SettingsViewModel>();

    return MaterialApp(
      title: 'Sonicly',
      debugShowCheckedModeBanner: false,
      themeMode: settingsVM.themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(isAmoled: settingsVM.isAmoled),
      home: const MainNavigationShell(),
    );
  }
}
