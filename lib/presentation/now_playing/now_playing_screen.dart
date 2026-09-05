import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/playback.dart';
import '../../domain/song.dart';
import '../view_models/player_view_model.dart';
import '../view_models/playlists_view_model.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_options_bottom_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.watch<PlayerViewModel>();
    final song = playerVM.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('No song playing')),
      );
    }

    final duration = playerVM.duration;
    final position = playerVM.position;
    final maxMs = duration.inMilliseconds.toDouble();
    final valueMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'PLAYING FROM QUEUE',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              song.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              SongOptionsBottomSheet.show(context, song);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artworkSize = (constraints.maxWidth * 0.75).clamp(180.0, 340.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Large Album Artwork
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ArtworkWidget(
                        artworkPath: song.artworkPath,
                        size: artworkSize,
                        borderRadius: 24,
                        fallbackIcon: Icons.music_note_rounded,
                      ),
                    ),
                  ),

                  // Song Title & Artist Info + Favorite
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          playerVM.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: playerVM.isFavorite ? Colors.redAccent : null,
                          size: 28,
                        ),
                        onPressed: () => playerVM.toggleFavorite(),
                      ),
                    ],
                  ),

                  // Scrubber Bar & Timestamps
                  Column(
                    children: [
                      SliderTheme(
                        data: theme.sliderTheme.copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: valueMs,
                          min: 0.0,
                          max: maxMs > 0 ? maxMs : 1.0,
                          onChanged: (val) {
                            playerVM.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerVM.isShuffle
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        iconSize: 24,
                        onPressed: () => playerVM.toggleShuffle(),
                      ),
                      // Skip 10s Backward
                      IconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        iconSize: 28,
                        onPressed: () {
                          final newPos = position - const Duration(seconds: 10);
                          playerVM.seek(newPos < Duration.zero ? Duration.zero : newPos);
                        },
                      ),
                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 36,
                        onPressed: () => playerVM.skipPrevious(),
                      ),
                      // Play / Pause
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            playerVM.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          iconSize: 42,
                          onPressed: () => playerVM.togglePlayPause(),
                        ),
                      ),
                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 36,
                        onPressed: () => playerVM.skipNext(),
                      ),
                      // Skip 10s Forward
                      IconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        iconSize: 28,
                        onPressed: () {
                          final newPos = position + const Duration(seconds: 10);
                          playerVM.seek(newPos > duration ? duration : newPos);
                        },
                      ),
                      // Repeat
                      IconButton(
                        icon: Icon(
                          playerVM.repeatMode == CustomRepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: playerVM.repeatMode != CustomRepeatMode.off
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        iconSize: 24,
                        onPressed: () => playerVM.cycleRepeatMode(),
                      ),
                    ],
                  ),

                  // Bottom Action Bar: Queue sheet & Add to playlist
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Format badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          song.format.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.playlist_add_rounded),
                            tooltip: 'Add to Playlist',
                            onPressed: () {
                              _showAddToPlaylist(context, song);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded),
                            tooltip: 'Playing Queue',
                            onPressed: () {
                              _showQueueBottomSheet(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, Song song) {
    final playlistsVM = context.read<PlaylistsViewModel>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add to Playlist',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (playlistsVM.playlists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No playlists created yet')),
                  )
                else
                  ...playlistsVM.playlists.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.queue_music_rounded),
                      title: Text(p.name),
                      subtitle: Text('${p.songCount} songs'),
                      onTap: () {
                        playlistsVM.addSongToPlaylist(p.id, song);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${p.name}')),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQueueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _QueueSheet(),
    );
  }
}

class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.watch<PlayerViewModel>();
    final queue = playerVM.queue;
    final currentIndex = playerVM.currentIndex;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Queue (${queue.length} tracks)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Drag to reorder',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: queue.isEmpty
                  ? const Center(child: Text('Queue is empty'))
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      itemCount: queue.length,
                      onReorderItem: (oldIndex, newIndex) {
                        playerVM.reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isNowPlaying = index == currentIndex;

                        return ListTile(
                          key: ValueKey('${item.id}_$index'),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              ArtworkWidget(
                                artworkPath: item.artworkPath,
                                size: 42,
                                borderRadius: 8,
                              ),
                              if (isNowPlaying)
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    playerVM.isPlaying
                                        ? Icons.equalizer_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isNowPlaying ? FontWeight.bold : FontWeight.w500,
                              color: isNowPlaying
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            item.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  playerVM.removeQueueItem(index);
                                },
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle_rounded),
                              ),
                            ],
                          ),
                          onTap: () {
                            playerVM.skipToQueueItem(index);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
