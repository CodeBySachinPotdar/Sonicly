import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/song.dart';
import '../now_playing/now_playing_screen.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final libraryVM = context.watch<LibraryViewModel>();
    final playerVM = context.watch<PlayerViewModel>();

    if (libraryVM.isLoading && libraryVM.songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (libraryVM.songs.isEmpty && !libraryVM.isScanning) {
      return EmptyState(
        icon: Icons.music_off_rounded,
        title: 'No Music Found',
        message: 'Scan your local storage to discover audio files on your device.',
        actionLabel: 'Scan Library',
        onAction: () => libraryVM.requestPermissionsAndScan(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sonicly'),
        actions: [
          IconButton(
            icon: libraryVM.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Rescan Library',
            onPressed: libraryVM.isScanning ? null : () => libraryVM.rescanLibrary(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => libraryVM.loadLibrary(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Scanning Banner
            if (libraryVM.isScanning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scanning (${libraryVM.scannedCount} files): ${libraryVM.currentScanFile}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Resume Card
            if (playerVM.currentSong != null) ...[
              _buildResumeCard(context, theme, playerVM),
              const SizedBox(height: 20),
            ],

            // Quick Section Shortcuts
            _buildSectionGrid(context, theme, libraryVM),
            const SizedBox(height: 24),

            // Recently Played Carousel
            if (libraryVM.recentlyPlayed.isNotEmpty) ...[
              _buildSectionHeader(
                theme,
                'Recently Played',
                onSeeAll: () => onNavigateToTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: libraryVM.recentlyPlayed.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final song = libraryVM.recentlyPlayed[index];
                    return _buildSongCard(context, theme, song, libraryVM.recentlyPlayed);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Most Played Carousel
            if (libraryVM.mostPlayed.isNotEmpty) ...[
              _buildSectionHeader(
                theme,
                'Most Played',
                onSeeAll: () => onNavigateToTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: libraryVM.mostPlayed.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final song = libraryVM.mostPlayed[index];
                    return _buildSongCard(context, theme, song, libraryVM.mostPlayed);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recently Added Carousel
            if (libraryVM.recentlyAdded.isNotEmpty) ...[
              _buildSectionHeader(
                theme,
                'Recently Added',
                onSeeAll: () => onNavigateToTab?.call(1),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: libraryVM.recentlyAdded.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final song = libraryVM.recentlyAdded[index];
                    return _buildSongCard(context, theme, song, libraryVM.recentlyAdded);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumeCard(
    BuildContext context,
    ThemeData theme,
    PlayerViewModel playerVM,
  ) {
    final song = playerVM.currentSong!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const NowPlayingScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ArtworkWidget(
                artworkPath: song.artworkPath,
                size: 56,
                borderRadius: 12,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUME PLAYBACK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                icon: Icon(
                  playerVM.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                iconSize: 28,
                onPressed: () => playerVM.togglePlayPause(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionGrid(
    BuildContext context,
    ThemeData theme,
    LibraryViewModel libraryVM,
  ) {
    final sections = [
      {'title': 'Songs', 'count': '${libraryVM.songs.length}', 'icon': Icons.music_note_rounded, 'tab': 1},
      {'title': 'Albums', 'count': '${libraryVM.albums.length}', 'icon': Icons.album_rounded, 'tab': 2},
      {'title': 'Artists', 'count': '${libraryVM.artists.length}', 'icon': Icons.person_rounded, 'tab': 3},
      {'title': 'Playlists', 'count': '${libraryVM.favorites.length} favs', 'icon': Icons.queue_music_rounded, 'tab': 4},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: sections.map((sec) {
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onNavigateToTab?.call(sec['tab'] as int),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      sec['icon'] as IconData,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec['title'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          sec['count'] as String,
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    ThemeData theme,
    Song song,
    List<Song> queueContext,
  ) {
    final playerVM = context.read<PlayerViewModel>();

    return SizedBox(
      width: 110,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => playerVM.playSong(song, queue: queueContext),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkWidget(
              artworkPath: song.artworkPath,
              size: 110,
              borderRadius: 12,
            ),
            const SizedBox(height: 6),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
