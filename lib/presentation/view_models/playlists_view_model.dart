import 'package:flutter/foundation.dart';
import '../../domain/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/song.dart';

class PlaylistsViewModel extends ChangeNotifier {
  final PlaylistRepository _playlistRepository;

  List<Playlist> _playlists = [];
  Playlist? _selectedPlaylist;
  List<Song> _selectedPlaylistSongs = [];
  bool _isLoading = false;

  PlaylistsViewModel({required this._playlistRepository});

  List<Playlist> get playlists => _playlists;
  Playlist? get selectedPlaylist => _selectedPlaylist;
  List<Song> get selectedPlaylistSongs => _selectedPlaylistSongs;
  bool get isLoading => _isLoading;

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();

    try {
      _playlists = await _playlistRepository.getAllPlaylists();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPlaylist(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedPlaylist = await _playlistRepository.getPlaylistById(id);
      _selectedPlaylistSongs = await _playlistRepository.getPlaylistSongs(id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist> createPlaylist(String name, {List<Song> initialSongs = const []}) async {
    final playlist = await _playlistRepository.createPlaylist(
      name,
      initialSongIds: initialSongs.map((s) => s.id).toList(),
    );
    await loadPlaylists();
    return playlist;
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _playlistRepository.renamePlaylist(id, newName);
    if (_selectedPlaylist?.id == id) {
      _selectedPlaylist = _selectedPlaylist?.copyWith(name: newName);
    }
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _playlistRepository.deletePlaylist(id);
    if (_selectedPlaylist?.id == id) {
      _selectedPlaylist = null;
      _selectedPlaylistSongs = [];
    }
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    await _playlistRepository.addSongToPlaylist(playlistId, song.id);
    if (_selectedPlaylist?.id == playlistId) {
      _selectedPlaylistSongs = await _playlistRepository.getPlaylistSongs(playlistId);
    }
    await loadPlaylists();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<Song> songs) async {
    await _playlistRepository.addSongsToPlaylist(
      playlistId,
      songs.map((s) => s.id).toList(),
    );
    if (_selectedPlaylist?.id == playlistId) {
      _selectedPlaylistSongs = await _playlistRepository.getPlaylistSongs(playlistId);
    }
    await loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    await _playlistRepository.removeSongFromPlaylist(playlistId, song.id);
    if (_selectedPlaylist?.id == playlistId) {
      _selectedPlaylistSongs = await _playlistRepository.getPlaylistSongs(playlistId);
    }
    await loadPlaylists();
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _selectedPlaylistSongs.length) return;
    if (newIndex < 0 || newIndex >= _selectedPlaylistSongs.length) return;

    final song = _selectedPlaylistSongs.removeAt(oldIndex);
    _selectedPlaylistSongs.insert(newIndex, song);
    notifyListeners();

    await _playlistRepository.reorderSongs(playlistId, oldIndex, newIndex);
  }
}
