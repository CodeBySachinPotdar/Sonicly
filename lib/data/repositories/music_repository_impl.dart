import 'dart:io';
import 'package:path/path.dart' as p;
import '../../domain/album.dart';
import '../../domain/artist.dart';
import '../../domain/playback.dart';
import '../../domain/repositories/music_repository.dart';
import '../../domain/song.dart';
import '../database/app_database.dart';
import '../scanner/file_scanner.dart';

class MusicRepositoryImpl implements MusicRepository {
  final AppDatabase _dbManager;

  MusicRepositoryImpl({AppDatabase? dbManager})
      : _dbManager = dbManager ?? AppDatabase.instance;

  @override
  Future<List<Song>> getAllSongs({
    SortField sortField = SortField.title,
    SortOrder sortOrder = SortOrder.ascending,
  }) async {
    final db = await _dbManager.database;

    String orderBy;
    final orderDirection = sortOrder == SortOrder.ascending ? 'ASC' : 'DESC';

    switch (sortField) {
      case SortField.title:
        orderBy = 's.title COLLATE NOCASE $orderDirection';
        break;
      case SortField.artist:
        orderBy = 's.artist COLLATE NOCASE $orderDirection, s.title COLLATE NOCASE ASC';
        break;
      case SortField.album:
        orderBy = 's.album COLLATE NOCASE $orderDirection, s.track_number ASC';
        break;
      case SortField.duration:
        orderBy = 's.duration_ms $orderDirection';
        break;
      case SortField.dateAdded:
        orderBy = 's.date_added $orderDirection';
        break;
      case SortField.playCount:
        orderBy = 's.play_count $orderDirection';
        break;
    }

    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      ORDER BY $orderBy
    ''');

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Song>> searchSongs(String query) async {
    if (query.trim().isEmpty) return getAllSongs();
    final db = await _dbManager.database;
    final pattern = '%${query.trim()}%';

    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.title LIKE ? OR s.artist LIKE ? OR s.album LIKE ?
      ORDER BY s.title COLLATE NOCASE ASC
    ''', [pattern, pattern, pattern]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Album>> getAlbums() async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT album, artist, COUNT(*) AS song_count, SUM(duration_ms) AS total_duration_ms,
             artwork_path, MAX(year) AS year
      FROM songs
      WHERE album != ''
      GROUP BY album, artist
      ORDER BY album COLLATE NOCASE ASC
    ''');

    return rows.map((r) {
      return Album(
        name: r['album'] as String,
        artist: (r['artist'] as String?)?.isNotEmpty == true
            ? r['artist'] as String
            : 'Unknown Artist',
        songCount: (r['song_count'] as num).toInt(),
        totalDurationMs: (r['total_duration_ms'] as num).toInt(),
        artworkPath: r['artwork_path'] as String?,
        year: (r['year'] as num?)?.toInt(),
      );
    }).toList();
  }

  @override
  Future<List<Song>> getAlbumSongs(String albumName, String artistName) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.album = ?
      ORDER BY s.disc_number ASC, s.track_number ASC, s.title COLLATE NOCASE ASC
    ''', [albumName]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Artist>> getArtists() async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT artist, COUNT(*) AS song_count, COUNT(DISTINCT album) AS album_count,
             SUM(duration_ms) AS total_duration_ms
      FROM songs
      WHERE artist != ''
      GROUP BY artist
      ORDER BY artist COLLATE NOCASE ASC
    ''');

    return rows.map((r) {
      return Artist(
        name: r['artist'] as String,
        songCount: (r['song_count'] as num).toInt(),
        albumCount: (r['album_count'] as num).toInt(),
        totalDurationMs: (r['total_duration_ms'] as num).toInt(),
      );
    }).toList();
  }

  @override
  Future<List<Song>> getArtistSongs(String artistName) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.artist = ?
      ORDER BY s.album COLLATE NOCASE ASC, s.track_number ASC, s.title COLLATE NOCASE ASC
    ''', [artistName]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Song>> getFavorites() async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, 1 AS is_favorite
      FROM songs s
      INNER JOIN favorites f ON s.id = f.song_id
      ORDER BY f.added_at DESC
    ''');

    return rows.map((r) => Song.fromMap(r, isFavorite: true)).toList();
  }

  @override
  Future<bool> toggleFavorite(String songId) async {
    final db = await _dbManager.database;
    final existing = await db.query(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
    );

    if (existing.isNotEmpty) {
      await db.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
      return false;
    } else {
      await db.insert('favorites', {
        'song_id': songId,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    }
  }

  @override
  Future<bool> isFavorite(String songId) async {
    final db = await _dbManager.database;
    final existing = await db.query(
      'favorites',
      where: 'song_id = ?',
      whereArgs: [songId],
      limit: 1,
    );
    return existing.isNotEmpty;
  }

  @override
  Future<List<Song>> getRecentlyPlayed({int limit = 50}) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.last_played_at IS NOT NULL
      ORDER BY s.last_played_at DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Song>> getMostPlayed({int limit = 50}) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.play_count > 0
      ORDER BY s.play_count DESC, s.last_played_at DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<List<Song>> getRecentlyAdded({int limit = 50}) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      ORDER BY s.date_added DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }

  @override
  Future<void> recordSongPlay(String songId) async {
    final db = await _dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate('''
      UPDATE songs
      SET play_count = play_count + 1, last_played_at = ?
      WHERE id = ?
    ''', [now, songId]);
  }

  @override
  Future<void> savePlaybackSession({
    required String? songId,
    required int positionMs,
    required List<String> queueSongIds,
    required int currentIndex,
    required bool isShuffle,
    required CustomRepeatMode repeatMode,
  }) async {
    final db = await _dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final queueCsv = queueSongIds.join(',');

    await db.rawInsert('''
      INSERT INTO playback_state (id, song_id, position_ms, queue_json, current_index, is_shuffle, repeat_mode, updated_at)
      VALUES (1, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        song_id = excluded.song_id,
        position_ms = excluded.position_ms,
        queue_json = excluded.queue_json,
        current_index = excluded.current_index,
        is_shuffle = excluded.is_shuffle,
        repeat_mode = excluded.repeat_mode,
        updated_at = excluded.updated_at
    ''', [
      songId,
      positionMs,
      queueCsv,
      currentIndex,
      isShuffle ? 1 : 0,
      repeatMode.index,
      now,
    ]);
  }

  @override
  Future<Map<String, dynamic>?> getLastPlaybackSession() async {
    final db = await _dbManager.database;
    final rows = await db.query('playback_state', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;

    final row = rows.first;
    final songId = row['song_id'] as String?;
    final queueCsv = (row['queue_json'] as String?) ?? '';
    final queueIds = queueCsv.isNotEmpty ? queueCsv.split(',') : <String>[];

    Song? currentSong;
    if (songId != null) {
      final songRows = await db.rawQuery('''
        SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
        FROM songs s
        LEFT JOIN favorites f ON s.id = f.song_id
        WHERE s.id = ?
        LIMIT 1
      ''', [songId]);
      if (songRows.isNotEmpty) {
        currentSong = Song.fromMap(songRows.first, isFavorite: songRows.first['is_favorite'] == 1);
      }
    }

    // Load full queue songs
    final List<Song> queueSongs = [];
    if (queueIds.isNotEmpty) {
      final placeholders = List.filled(queueIds.length, '?').join(',');
      final songRows = await db.rawQuery('''
        SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
        FROM songs s
        LEFT JOIN favorites f ON s.id = f.song_id
        WHERE s.id IN ($placeholders)
      ''', queueIds);

      final songMap = {
        for (final r in songRows)
          r['id'] as String: Song.fromMap(r, isFavorite: r['is_favorite'] == 1),
      };

      for (final id in queueIds) {
        if (songMap.containsKey(id)) {
          queueSongs.add(songMap[id]!);
        }
      }
    }

    return {
      'currentSong': currentSong,
      'positionMs': (row['position_ms'] as num?)?.toInt() ?? 0,
      'queue': queueSongs,
      'currentIndex': (row['current_index'] as num?)?.toInt() ?? -1,
      'isShuffle': (row['is_shuffle'] as int?) == 1,
      'repeatMode': CustomRepeatMode.values[(row['repeat_mode'] as num?)?.toInt() ?? 0],
    };
  }

  @override
  Future<List<String>> getFolders() async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('SELECT DISTINCT path FROM songs');
    final Set<String> folders = {};

    for (final row in rows) {
      final filePath = row['path'] as String;
      final dir = p.dirname(filePath);
      folders.add(dir);
    }

    final sorted = folders.toList()..sort();
    return sorted;
  }

  @override
  Future<List<Song>> getSongsInFolder(String folderPath) async {
    final db = await _dbManager.database;
    final pattern = '$folderPath%';
    final rows = await db.rawQuery('''
      SELECT s.*, CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM songs s
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE s.path LIKE ?
      ORDER BY s.title COLLATE NOCASE ASC
    ''', [pattern]);

    return rows
        .map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1))
        .where((s) => p.dirname(s.path) == folderPath)
        .toList();
  }

  @override
  Future<int> scanDirectory(
    String path, {
    void Function(int current, String fileName)? onProgress,
  }) async {
    final dir = Directory(path);
    return await FileScanner.scanDirectory(dir, onProgress: onProgress);
  }

  @override
  Future<void> clearHistory() async {
    final db = await _dbManager.database;
    await db.rawUpdate('''
      UPDATE songs SET play_count = 0, last_played_at = NULL
    ''');
    await db.delete('playback_state');
  }
}
