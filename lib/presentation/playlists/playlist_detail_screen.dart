import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/playlist.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../view_models/playlists_view_model.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_options_bottom_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistsViewModel>().selectPlaylist(widget.playlist.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlistsVM = context.watch<PlaylistsViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final currentPlaylist = playlistsVM.selectedPlaylist ?? widget.playlist;
    final songs = playlistsVM.selectedPlaylistSongs;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPlaylist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Rename Playlist',
            onPressed: () => _showRenameDialog(context, playlistsVM, currentPlaylist),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Songs',
            onPressed: () => _showAddSongsModal(context, playlistsVM, currentPlaylist),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Playlist',
            onPressed: () => _confirmDelete(context, playlistsVM, currentPlaylist),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${songs.length} songs • ${currentPlaylist.durationFormatted}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: songs.isEmpty
                          ? null
                          : () => playerVM.playSong(songs.first, queue: songs, initialIndex: 0),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Play'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: songs.isEmpty
                          ? null
                          : () async {
                              if (!playerVM.isShuffle) await playerVM.toggleShuffle();
                              playerVM.playSong(songs.first, queue: songs);
                            },
                      icon: const Icon(Icons.shuffle_rounded, size: 18),
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
          const Divider(height: 1),
          Expanded(
            child: songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_note_rounded, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('This playlist is empty'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => _showAddSongsModal(context, playlistsVM, currentPlaylist),
                          child: const Text('Add Songs'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorderItem: (oldIndex, newIndex) {
                      playlistsVM.reorderSongs(currentPlaylist.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        key: ValueKey('${song.id}_$index'),
                        leading: ArtworkWidget(
                          artworkPath: song.artworkPath,
                          size: 42,
                          borderRadius: 8,
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.durationFormatted}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onPressed: () {
                                SongOptionsBottomSheet.show(
                                  context,
                                  song,
                                  fromPlaylistId: currentPlaylist.id,
                                );
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle_rounded),
                            ),
                          ],
                        ),
                        onTap: () {
                          playerVM.playSong(song, queue: songs, initialIndex: index);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    PlaylistsViewModel playlistsVM,
    Playlist playlist,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                playlistsVM.renamePlaylist(playlist.id, newName);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PlaylistsViewModel playlistsVM,
    Playlist playlist,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"? The songs will remain on your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              playlistsVM.deletePlaylist(playlist.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddSongsModal(
    BuildContext context,
    PlaylistsViewModel playlistsVM,
    Playlist playlist,
  ) {
    final libraryVM = context.read<LibraryViewModel>();
    final allSongs = libraryVM.songs;
    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Songs to ${playlist.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        FilledButton(
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () {
                                  final songsToAdd = allSongs
                                      .where((s) => selectedIds.contains(s.id))
                                      .toList();
                                  playlistsVM.addSongsToPlaylist(playlist.id, songsToAdd);
                                  Navigator.pop(ctx);
                                },
                          child: Text('Add (${selectedIds.length})'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        final isSelected = selectedIds.contains(song.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedIds.add(song.id);
                              } else {
                                selectedIds.remove(song.id);
                              }
                            });
                          },
                          secondary: ArtworkWidget(
                            artworkPath: song.artworkPath,
                            size: 40,
                            borderRadius: 6,
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
