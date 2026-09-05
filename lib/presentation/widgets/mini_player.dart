import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../now_playing/now_playing_screen.dart';
import '../view_models/player_view_model.dart';
import 'artwork_widget.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.watch<PlayerViewModel>();
    final song = playerVM.currentSong;

    if (song == null) return const SizedBox.shrink();

    final durationMs = playerVM.duration.inMilliseconds;
    final positionMs = playerVM.position.inMilliseconds;
    final progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const NowPlayingScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear Progress Bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ArtworkWidget(
                    artworkPath: song.artworkPath,
                    size: 44,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  IconButton(
                    icon: Icon(
                      playerVM.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: playerVM.isFavorite ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                    ),
                    iconSize: 22,
                    splashRadius: 20,
                    onPressed: () => playerVM.toggleFavorite(),
                  ),
                  IconButton(
                    icon: Icon(
                      playerVM.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    iconSize: 36,
                    splashRadius: 22,
                    onPressed: () => playerVM.togglePlayPause(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 26,
                    splashRadius: 20,
                    color: theme.colorScheme.onSurface,
                    onPressed: () => playerVM.skipNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
