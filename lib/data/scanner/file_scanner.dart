import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../domain/song.dart';
import '../cache/artwork_cache.dart';
import '../database/app_database.dart';
import '../metadata/audio_metadata_reader.dart';

class FileScanner {
  static const Set<String> supportedExtensions = {
    '.mp3',
    '.m4a',
    '.aac',
    '.flac',
    '.wav',
    '.ogg',
    '.opus',
    '.aiff',
    '.aif',
    '.wma',
  };

  /// Generates a stable unique identifier for a file path.
  static String generateId(String path) {
    return md5.convert(path.codeUnits).toString();
  }

  /// Scans a directory recursively and indexes all discovered audio files into the database.
  static Future<int> scanDirectory(
    Directory directory, {
    void Function(int count, String currentFileName)? onProgress,
  }) async {
    if (!await directory.exists()) return 0;

    final db = await AppDatabase.instance.database;

    // Fetch existing song modified times to skip re-reading unchanged files
    final existingSongsRows = await db.rawQuery(
      'SELECT id, path, date_modified FROM songs',
    );
    final Map<String, int> existingFiles = {
      for (final row in existingSongsRows)
        row['path'] as String: (row['date_modified'] as num).toInt(),
    };

    final List<File> audioFiles = [];
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (_) {
      // Permission or I/O error on specific directory
    }

    if (audioFiles.isEmpty) return 0;

    int scannedCount = 0;
    final List<Song> batchToInsert = [];

    for (final file in audioFiles) {
      final path = file.path;
      final fileName = p.basename(path);
      scannedCount++;
      onProgress?.call(scannedCount, fileName);

      try {
        final stat = await file.stat();
        final modifiedMs = stat.modified.millisecondsSinceEpoch;

        // If file already in DB and unchanged, skip re-parsing
        if (existingFiles.containsKey(path) && existingFiles[path] == modifiedMs) {
          continue;
        }

        final metadata = await AudioMetadataReader.readMetadata(file);
        final songId = generateId(path);

        String? artworkPath;
        if (metadata.artworkBytes != null && metadata.artworkBytes!.isNotEmpty) {
          artworkPath = await ArtworkCache.instance.saveArtwork(
            songId,
            metadata.artworkBytes!,
            extension: metadata.artworkMime?.contains('png') == true ? 'png' : 'jpg',
          );
        }

        final song = Song(
          id: songId,
          path: path,
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album,
          albumArtist: metadata.albumArtist,
          durationMs: metadata.durationMs,
          size: stat.size,
          dateAdded: stat.changed.millisecondsSinceEpoch,
          dateModified: modifiedMs,
          format: p.extension(path).replaceFirst('.', '').toLowerCase(),
          trackNumber: metadata.trackNumber,
          discNumber: metadata.discNumber,
          year: metadata.year,
          genre: metadata.genre,
          artworkPath: artworkPath,
          hasArtwork: artworkPath != null,
        );

        batchToInsert.add(song);

        // Commit batch in chunks of 50
        if (batchToInsert.length >= 50) {
          await _insertBatch(db, batchToInsert);
          batchToInsert.clear();
        }
      } catch (_) {
        // Continue scanning next file
      }
    }

    if (batchToInsert.isNotEmpty) {
      await _insertBatch(db, batchToInsert);
      batchToInsert.clear();
    }

    // Clean up dead files that were deleted from storage
    await _cleanupDeadFiles(db);

    return scannedCount;
  }

  static Future<void> _insertBatch(Database db, List<Song> songs) async {
    final batch = db.batch();
    for (final song in songs) {
      batch.insert(
        'songs',
        song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _cleanupDeadFiles(Database db) async {
    try {
      final rows = await db.rawQuery('SELECT id, path FROM songs');
      final List<String> deadSongIds = [];

      for (final row in rows) {
        final path = row['path'] as String;
        final file = File(path);
        if (!await file.exists()) {
          deadSongIds.add(row['id'] as String);
        }
      }

      if (deadSongIds.isNotEmpty) {
        final batch = db.batch();
        for (final id in deadSongIds) {
          batch.delete('songs', where: 'id = ?', whereArgs: [id]);
        }
        await batch.commit(noResult: true);
      }
    } catch (_) {}
  }
}
