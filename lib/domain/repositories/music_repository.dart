import '../song.dart';
import '../album.dart';
import '../artist.dart';
import '../playback.dart';

abstract class MusicRepository {
  Future<List<Song>> getAllSongs({
    SortField sortField = SortField.title,
    SortOrder sortOrder = SortOrder.ascending,
  });

  Future<List<Song>> searchSongs(String query);

  Future<List<Album>> getAlbums();

  Future<List<Song>> getAlbumSongs(String albumName, String artistName);

  Future<List<Artist>> getArtists();

  Future<List<Song>> getArtistSongs(String artistName);

  Future<List<Song>> getFavorites();

  Future<bool> toggleFavorite(String songId);

  Future<bool> isFavorite(String songId);

  Future<List<Song>> getRecentlyPlayed({int limit = 50});

  Future<List<Song>> getMostPlayed({int limit = 50});

  Future<List<Song>> getRecentlyAdded({int limit = 50});

  Future<void> recordSongPlay(String songId);

  Future<void> savePlaybackSession({
    required String? songId,
    required int positionMs,
    required List<String> queueSongIds,
    required int currentIndex,
    required bool isShuffle,
    required CustomRepeatMode repeatMode,
  });

  Future<Map<String, dynamic>?> getLastPlaybackSession();

  Future<List<String>> getFolders();

  Future<List<Song>> getSongsInFolder(String folderPath);

  Future<int> scanDirectory(
    String path, {
    void Function(int current, String fileName)? onProgress,
  });

  Future<void> clearHistory();
}
