import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/song.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import 'artwork_widget.dart';
import 'song_options_bottom_sheet.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? queueContext;
  final int? indexInQueue;
  final String? fromPlaylistId;
  final bool showArtwork;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    this.queueContext,
    this.indexInQueue,
    this.fromPlaylistId,
    this.showArtwork = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.watch<PlayerViewModel>();
    final isCurrent = playerVM.currentSong?.id == song.id;
    final isPlaying = isCurrent && playerVM.isPlaying;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: showArtwork
          ? Stack(
              alignment: Alignment.center,
              children: [
                ArtworkWidget(
                  artworkPath: song.artworkPath,
                  size: 48,
                  borderRadius: 10,
                ),
                if (isCurrent)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isPlaying ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            )
          : null,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '${song.artist} • ${song.album}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            song.durationFormatted,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.format != 'mp3')
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                song.format.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: song.isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            iconSize: 20,
            splashRadius: 20,
            tooltip: song.isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () {
              context.read<LibraryViewModel>().toggleFavorite(song);
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            iconSize: 20,
            splashRadius: 20,
            onPressed: () {
              SongOptionsBottomSheet.show(
                context,
                song,
                fromPlaylistId: fromPlaylistId,
              );
            },
          ),
        ],
      ),
      onTap: onTap ??
          () {
            playerVM.playSong(
              song,
              queue: queueContext,
              initialIndex: indexInQueue,
            );
          },
    );
  }
}
