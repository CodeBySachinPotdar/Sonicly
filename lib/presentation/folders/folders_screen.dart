import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../domain/song.dart';
import '../view_models/library_view_model.dart';
import '../view_models/player_view_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_tile.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  String? _selectedFolder;
  List<Song> _folderSongs = [];
  bool _isLoadingFolder = false;

  Future<void> _openFolder(String folderPath) async {
    setState(() {
      _selectedFolder = folderPath;
      _isLoadingFolder = true;
    });

    final libraryVM = context.read<LibraryViewModel>();
    final songs = await libraryVM.getSongsInFolder(folderPath);

    if (mounted) {
      setState(() {
        _folderSongs = songs;
        _isLoadingFolder = false;
      });
    }
  }

  Future<void> _pickAndScanFolder() async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath();
      if (selectedPath != null && mounted) {
        final libraryVM = context.read<LibraryViewModel>();
        await libraryVM.scanCustomDirectory(selectedPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scanned directory: $selectedPath')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final libraryVM = context.watch<LibraryViewModel>();
    final folders = libraryVM.folders;

    if (_selectedFolder != null) {
      return _buildFolderDetailView(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Folders (${folders.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_rounded),
            tooltip: 'Add Custom Folder',
            onPressed: _pickAndScanFolder,
          ),
        ],
      ),
      body: folders.isEmpty
          ? EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No Folders Discovered',
              message: 'Scan your storage or add a custom music folder.',
              actionLabel: 'Add Folder',
              onAction: _pickAndScanFolder,
            )
          : ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folderPath = folders[index];
                final folderName = p.basename(folderPath);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_rounded),
                  ),
                  title: Text(
                    folderName.isNotEmpty ? folderName : folderPath,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    folderPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openFolder(folderPath),
                );
              },
            ),
    );
  }

  Widget _buildFolderDetailView(BuildContext context) {
    final theme = Theme.of(context);
    final playerVM = context.read<PlayerViewModel>();
    final folderName = p.basename(_selectedFolder!);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _selectedFolder = null;
              _folderSongs = [];
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folderName),
            Text(
              _selectedFolder!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_folderSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      playerVM.playSong(_folderSongs.first, queue: _folderSongs, initialIndex: 0);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      if (!playerVM.isShuffle) await playerVM.toggleShuffle();
                      playerVM.playSong(_folderSongs.first, queue: _folderSongs);
                    },
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Shuffle'),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _isLoadingFolder
                ? const Center(child: CircularProgressIndicator())
                : _folderSongs.isEmpty
                    ? const Center(child: Text('No audio files in this folder'))
                    : ListView.builder(
                        itemCount: _folderSongs.length,
                        itemBuilder: (context, index) {
                          final song = _folderSongs[index];
                          return SongTile(
                            song: song,
                            queueContext: _folderSongs,
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
