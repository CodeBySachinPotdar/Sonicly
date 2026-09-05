import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/library_view_model.dart';
import '../widgets/empty_state.dart';
import 'artist_detail_screen.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final libraryVM = context.watch<LibraryViewModel>();
    final artists = libraryVM.artists;

    return Scaffold(
      appBar: AppBar(
        title: Text('Artists (${artists.length})'),
      ),
      body: artists.isEmpty
          ? EmptyState(
              icon: Icons.person_rounded,
              title: 'No Artists Found',
              message: 'Scan your local storage to discover artists.',
              actionLabel: 'Rescan Library',
              onAction: () => libraryVM.rescanLibrary(),
            )
          : ListView.builder(
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    artist.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${artist.albumCount} albums • ${artist.songCount} songs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
