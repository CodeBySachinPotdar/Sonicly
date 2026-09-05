import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/artist.dart';
import '../../domain/song.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/song_tile.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final libraryVM = context.read<LibraryViewModel>();
    final songs = await libraryVM.getArtistSongs(widget.artist.name);
    if (mounted) {
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.read<PlayerViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artist.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.artist.albumCount} albums • ${widget.artist.songCount} songs',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _songs.isEmpty
                      ? null
                      : () => playerVM.playSong(_songs.first, queue: _songs, initialIndex: 0),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play All'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _songs.isEmpty
                      ? null
                      : () async {
                          if (!playerVM.isShuffle) await playerVM.toggleShuffle();
                          playerVM.playSong(_songs.first, queue: _songs);
                        },
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _songs.length,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return SongTile(
                        song: song,
                        queueContext: _songs,
                        indexInQueue: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
