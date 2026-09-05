import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryVM = context.watch<LibraryViewModel>();
    final playerVM = context.read<PlayerViewModel>();
    final favorites = libraryVM.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites (${favorites.length})'),
      ),
      body: Column(
        children: [
          if (favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      playerVM.playSong(favorites.first, queue: favorites, initialIndex: 0);
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
                      if (!playerVM.isShuffle) await playerVM.toggleShuffle();
                      playerVM.playSong(favorites.first, queue: favorites);
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
          Expanded(
            child: favorites.isEmpty
                ? const EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'No Favorites Yet',
                    message: 'Tap the heart icon on any song to add it to your favorites.',
                  )
                : ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      final song = favorites[index];
                      return SongTile(
                        song: song,
                        queueContext: favorites,
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
