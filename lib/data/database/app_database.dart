import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'music_player.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        path TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT NOT NULL,
        album_artist TEXT,
        duration_ms INTEGER NOT NULL,
        size INTEGER NOT NULL,
        date_added INTEGER NOT NULL,
        date_modified INTEGER NOT NULL,
        format TEXT NOT NULL,
        track_number INTEGER,
        disc_number INTEGER,
        year INTEGER,
        genre TEXT,
        artwork_path TEXT,
        has_artwork INTEGER DEFAULT 0,
        play_count INTEGER DEFAULT 0,
        last_played_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id, sort_order),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        song_id TEXT PRIMARY KEY,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE playback_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        song_id TEXT,
        position_ms INTEGER DEFAULT 0,
        queue_json TEXT,
        current_index INTEGER DEFAULT -1,
        is_shuffle INTEGER DEFAULT 0,
        repeat_mode INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Performance indexes for library queries and search
    await db.execute('CREATE INDEX idx_songs_title ON songs(title COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs(artist COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_songs_album ON songs(album COLLATE NOCASE)');
    await db.execute('CREATE INDEX idx_songs_play_count ON songs(play_count DESC)');
    await db.execute('CREATE INDEX idx_songs_date_added ON songs(date_added DESC)');
    await db.execute('CREATE INDEX idx_playlist_songs_playlist ON playlist_songs(playlist_id, sort_order)');
    await db.execute('CREATE INDEX idx_favorites_added ON favorites(added_at DESC)');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
