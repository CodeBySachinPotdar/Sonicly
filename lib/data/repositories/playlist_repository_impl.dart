import 'package:uuid/uuid.dart';
import '../../domain/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/song.dart';
import '../database/app_database.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final AppDatabase _dbManager;
  final _uuid = const Uuid();

  PlaylistRepositoryImpl({AppDatabase? dbManager})
      : _dbManager = dbManager ?? AppDatabase.instance;

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT p.*,
             COUNT(ps.song_id) AS song_count,
             COALESCE(SUM(s.duration_ms), 0) AS total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      LEFT JOIN songs s ON ps.song_id = s.id
      GROUP BY p.id
      ORDER BY p.name COLLATE NOCASE ASC
    ''');

    return rows.map((r) => Playlist.fromMap(r)).toList();
  }

  @override
  Future<Playlist?> getPlaylistById(String id) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT p.*,
             COUNT(ps.song_id) AS song_count,
             COALESCE(SUM(s.duration_ms), 0) AS total_duration_ms
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      LEFT JOIN songs s ON ps.song_id = s.id
      WHERE p.id = ?
      GROUP BY p.id
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    final songs = await getPlaylistSongs(id);
    return Playlist.fromMap(rows.first, songs: songs);
  }

  @override
  Future<Playlist> createPlaylist(
    String name, {
    List<String> initialSongIds = const [],
  }) async {
    final db = await _dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();

    await db.insert('playlists', {
      'id': id,
      'name': name.trim(),
      'created_at': now,
      'updated_at': now,
    });

    if (initialSongIds.isNotEmpty) {
      final batch = db.batch();
      for (int i = 0; i < initialSongIds.length; i++) {
        batch.insert('playlist_songs', {
          'playlist_id': id,
          'song_id': initialSongIds[i],
          'sort_order': i,
        });
      }
      await batch.commit(noResult: true);
    }

    final songs = await getPlaylistSongs(id);
    return Playlist(
      id: id,
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      songCount: songs.length,
      totalDurationMs: songs.fold<int>(0, (sum, s) => sum + s.durationMs),
      songs: songs,
    );
  }

  @override
  Future<void> renamePlaylist(String id, String newName) async {
    final db = await _dbManager.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'playlists',
      {'name': newName.trim(), 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deletePlaylist(String id) async {
    final db = await _dbManager.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final db = await _dbManager.database;

    // Check if song already exists in playlist to avoid duplicate ordering issues
    final existing = await db.query(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
    if (existing.isNotEmpty) return;

    final maxOrderRows = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    final maxOrder = (maxOrderRows.first['max_order'] as num?)?.toInt() ?? -1;

    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'sort_order': maxOrder + 1,
    });

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('playlists', {'updated_at': now}, where: 'id = ?', whereArgs: [playlistId]);
  }

  @override
  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    final db = await _dbManager.database;
    final maxOrderRows = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_order FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    int currentOrder = ((maxOrderRows.first['max_order'] as num?)?.toInt() ?? -1) + 1;

    final existingRows = await db.query(
      'playlist_songs',
      columns: ['song_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    final existingSongIds = existingRows.map((r) => r['song_id'] as String).toSet();

    final batch = db.batch();
    for (final songId in songIds) {
      if (!existingSongIds.contains(songId)) {
        batch.insert('playlist_songs', {
          'playlist_id': playlistId,
          'song_id': songId,
          'sort_order': currentOrder++,
        });
      }
    }
    await batch.commit(noResult: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('playlists', {'updated_at': now}, where: 'id = ?', whereArgs: [playlistId]);
  }

  @override
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await _dbManager.database;
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );

    // Re-index remaining songs
    final remainingRows = await db.query(
      'playlist_songs',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'sort_order ASC',
    );

    final batch = db.batch();
    for (int i = 0; i < remainingRows.length; i++) {
      batch.update(
        'playlist_songs',
        {'sort_order': i},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, remainingRows[i]['song_id']],
      );
    }
    await batch.commit(noResult: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('playlists', {'updated_at': now}, where: 'id = ?', whereArgs: [playlistId]);
  }

  @override
  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    final db = await _dbManager.database;
    final songs = await getPlaylistSongs(playlistId);
    if (oldIndex < 0 || oldIndex >= songs.length) return;
    if (newIndex < 0 || newIndex >= songs.length) return;

    final song = songs.removeAt(oldIndex);
    songs.insert(newIndex, song);

    final batch = db.batch();
    for (int i = 0; i < songs.length; i++) {
      batch.update(
        'playlist_songs',
        {'sort_order': i},
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songs[i].id],
      );
    }
    await batch.commit(noResult: true);

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('playlists', {'updated_at': now}, where: 'id = ?', whereArgs: [playlistId]);
  }

  @override
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final db = await _dbManager.database;
    final rows = await db.rawQuery('''
      SELECT s.*,
             CASE WHEN f.song_id IS NOT NULL THEN 1 ELSE 0 END AS is_favorite
      FROM playlist_songs ps
      JOIN songs s ON ps.song_id = s.id
      LEFT JOIN favorites f ON s.id = f.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.sort_order ASC
    ''', [playlistId]);

    return rows.map((r) => Song.fromMap(r, isFavorite: r['is_favorite'] == 1)).toList();
  }
}
