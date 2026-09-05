import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../favorites/favorites_screen.dart';
import '../view_models/library_view_model.dart';
import '../view_models/playlists_view_model.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistsViewModel>().loadPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistsVM = context.watch<PlaylistsViewModel>();
    final libraryVM = context.watch<LibraryViewModel>();
    final playlists = playlistsVM.playlists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Playlist',
            onPressed: () => _showCreatePlaylistDialog(context, playlistsVM),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Favorites System Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.pinkAccent, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
            ),
            title: const Text(
              'Favorites',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${libraryVM.favorites.length} songs'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          const Divider(height: 1),

          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.queue_music_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No custom playlists yet'),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => _showCreatePlaylistDialog(context, playlistsVM),
                      child: const Text('Create Playlist'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...playlists.map(
              (playlist) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.queue_music_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                title: Text(
                  playlist.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${playlist.songCount} songs • ${playlist.durationFormatted}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: playlist),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, PlaylistsViewModel playlistsVM) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter playlist name',
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
                playlistsVM.createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
