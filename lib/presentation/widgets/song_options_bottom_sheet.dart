import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/song.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../view_models/playlists_view_model.dart';
import 'artwork_widget.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;
  final String? fromPlaylistId;

  const SongOptionsBottomSheet({
    super.key,
    required this.song,
    this.fromPlaylistId,
  });

  static Future<void> show(BuildContext context, Song song, {String? fromPlaylistId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SongOptionsBottomSheet(
        song: song,
        fromPlaylistId: fromPlaylistId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.read<PlayerViewModel>();
    final libraryVM = context.read<LibraryViewModel>();
    final playlistsVM = context.read<PlaylistsViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Song header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ArtworkWidget(
                    artworkPath: song.artworkPath,
                    size: 52,
                    borderRadius: 10,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${song.artist} • ${song.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      song.format.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Action Items
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: const Text('Play Next'),
              onTap: () {
                playerVM.insertNext(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playing "${song.title}" next')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Add to Queue'),
              onTap: () {
                playerVM.addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added "${song.title}" to queue')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: song.isFavorite ? Colors.redAccent : null,
              ),
              title: Text(song.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                libraryVM.toggleFavorite(song);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, song, playlistsVM);
              },
            ),
            if (fromPlaylistId != null)
              ListTile(
                leading: const Icon(Icons.playlist_remove_rounded, color: Colors.redAccent),
                title: const Text('Remove from Playlist', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  playlistsVM.removeSongFromPlaylist(fromPlaylistId!, song);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Track Details'),
              onTap: () {
                Navigator.pop(context);
                _showTrackDetailsDialog(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    Song song,
    PlaylistsViewModel playlistsVM,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          content: SizedBox(
            width: double.maxFinite,
            child: playlistsVM.playlists.isEmpty
                ? const Text('No playlists created yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlistsVM.playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlistsVM.playlists[index];
                      return ListTile(
                        leading: const Icon(Icons.queue_music_rounded),
                        title: Text(playlist.name),
                        subtitle: Text('${playlist.songCount} songs'),
                        onTap: () {
                          playlistsVM.addSongToPlaylist(playlist.id, song);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added to ${playlist.name}')),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showCreatePlaylistDialog(context, song, playlistsVM);
              },
              child: const Text('New Playlist'),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    Song song,
    PlaylistsViewModel playlistsVM,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  playlistsVM.createPlaylist(name, initialSongs: [song]);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created playlist "$name"')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showTrackDetailsDialog(BuildContext context, Song song) {
    final sizeMb = (song.size / (1024 * 1024)).toStringAsFixed(2);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Track Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(theme, 'Title', song.title),
                _detailRow(theme, 'Artist', song.artist),
                _detailRow(theme, 'Album', song.album),
                _detailRow(theme, 'Duration', song.durationFormatted),
                _detailRow(theme, 'Format', song.format.toUpperCase()),
                _detailRow(theme, 'File Size', '$sizeMb MB'),
                if (song.year != null) _detailRow(theme, 'Year', '${song.year}'),
                if (song.trackNumber != null) _detailRow(theme, 'Track #', '${song.trackNumber}'),
                if (song.genre != null) _detailRow(theme, 'Genre', song.genre!),
                _detailRow(theme, 'Plays', '${song.playCount}'),
                _detailRow(theme, 'Location', song.path),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 1),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
