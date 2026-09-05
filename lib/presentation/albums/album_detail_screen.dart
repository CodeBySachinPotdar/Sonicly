import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/album.dart';
import '../../domain/song.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_tile.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final libraryVM = context.read<LibraryViewModel>();
    final songs = await libraryVM.getAlbumSongs(widget.album.name, widget.album.artist);
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                color: theme.colorScheme.surfaceContainer,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ArtworkWidget(
                      artworkPath: widget.album.artworkPath,
                      size: 160,
                      borderRadius: 16,
                      fallbackIcon: Icons.album_rounded,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.artist,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.album.songCount} songs • ${widget.album.durationFormatted}${widget.album.year != null ? ' • ${widget.album.year}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _songs.isEmpty
                            ? null
                            : () => playerVM.playSong(_songs.first, queue: _songs, initialIndex: 0),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = _songs[index];
                  return SongTile(
                    song: song,
                    queueContext: _songs,
                    indexInQueue: index,
                    showArtwork: false,
                  );
                },
                childCount: _songs.length,
              ),
            ),
        ],
      ),
    );
  }
}
