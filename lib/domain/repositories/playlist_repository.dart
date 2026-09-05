import '../playlist.dart';
import '../song.dart';

abstract class PlaylistRepository {
  Future<List<Playlist>> getAllPlaylists();

  Future<Playlist?> getPlaylistById(String id);

  Future<Playlist> createPlaylist(String name, {List<String> initialSongIds = const []});

  Future<void> renamePlaylist(String id, String newName);

  Future<void> deletePlaylist(String id);

  Future<void> addSongToPlaylist(String playlistId, String songId);

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds);

  Future<void> removeSongFromPlaylist(String playlistId, String songId);

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex);

  Future<List<Song>> getPlaylistSongs(String playlistId);
}
