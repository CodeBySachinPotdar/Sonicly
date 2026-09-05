import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/playback.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryVM = context.watch<LibraryViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final songs = libraryVM.songs;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => libraryVM.setSearchQuery(val),
              )
            : Text('Songs (${songs.length})'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  libraryVM.setSearchQuery('');
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Songs',
            onPressed: () => _showSortModal(context, libraryVM),
          ),
        ],
      ),
      body: Column(
        children: [
          // Action row: Play All & Shuffle All
          if (songs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      playerVM.playSong(songs.first, queue: songs, initialIndex: 0);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Play All'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      if (!playerVM.isShuffle) {
                        await playerVM.toggleShuffle();
                      }
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
            ),
          const Divider(height: 1),

          // Songs List
          Expanded(
            child: songs.isEmpty
                ? EmptyState(
                    icon: Icons.music_note_rounded,
                    title: _searchController.text.isNotEmpty
                        ? 'No Results'
                        : 'No Songs Found',
                    message: _searchController.text.isNotEmpty
                        ? 'Try searching with a different keyword'
                        : 'No audio files discovered yet. Pull down or tap to scan.',
                    actionLabel: _searchController.text.isNotEmpty ? null : 'Rescan',
                    onAction: _searchController.text.isNotEmpty
                        ? null
                        : () => libraryVM.rescanLibrary(),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return SongTile(
                        song: song,
                        queueContext: songs,
                        indexInQueue: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSortModal(BuildContext context, LibraryViewModel libraryVM) {
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
                  'Sort Songs By',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _sortOption(ctx, libraryVM, 'Title', SortField.title),
                _sortOption(ctx, libraryVM, 'Artist', SortField.artist),
                _sortOption(ctx, libraryVM, 'Album', SortField.album),
                _sortOption(ctx, libraryVM, 'Duration', SortField.duration),
                _sortOption(ctx, libraryVM, 'Date Added', SortField.dateAdded),
                _sortOption(ctx, libraryVM, 'Most Played', SortField.playCount),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Ascending'),
                      selected: libraryVM.sortOrder == SortOrder.ascending,
                      onSelected: (_) {
                        libraryVM.setSort(libraryVM.sortField, SortOrder.ascending);
                        Navigator.pop(ctx);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Descending'),
                      selected: libraryVM.sortOrder == SortOrder.descending,
                      onSelected: (_) {
                        libraryVM.setSort(libraryVM.sortField, SortOrder.descending);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortOption(
    BuildContext ctx,
    LibraryViewModel vm,
    String label,
    SortField field,
  ) {
    final isSelected = vm.sortField == field;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary)
          : null,
      onTap: () {
        vm.setSort(field, vm.sortOrder);
        Navigator.pop(ctx);
      },
    );
  }
}
