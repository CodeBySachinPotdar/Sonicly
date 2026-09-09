import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/data/scanner/file_scanner.dart';
import 'package:music_player/domain/album.dart';
import 'package:music_player/domain/artist.dart';
import 'package:music_player/domain/playlist.dart';
import 'package:music_player/domain/song.dart';

void main() {
  group('Domain Models Tests', () {
    test('Song model formatting and serialization', () {
      const song = Song(
        id: 'test-1',
        path: '/music/test.flac',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        durationMs: 354000,
        size: 45000000,
        dateAdded: 1600000000,
        dateModified: 1600000000,
        format: 'flac',
        trackNumber: 11,
        year: 1975,
        genre: 'Rock',
        isFavorite: true,
      );

      expect(song.durationFormatted, '5:54');
      expect(song.duration.inSeconds, 354);

      final map = song.toMap();
      expect(map['title'], 'Bohemian Rhapsody');
      expect(map['format'], 'flac');
      expect(map['track_number'], 11);

      final reconstructed = Song.fromMap(map, isFavorite: true);
      expect(reconstructed.id, song.id);
      expect(reconstructed.title, song.title);
      expect(reconstructed.artist, song.artist);
      expect(reconstructed.isFavorite, isTrue);
    });

    test('Album model duration formatting', () {
      const album = Album(
        name: 'The Dark Side of the Moon',
        artist: 'Pink Floyd',
        songCount: 10,
        totalDurationMs: 2580000, // 43 minutes
      );

      expect(album.durationFormatted, '43m');
      expect(album.songCount, 10);
    });

    test('Artist model calculations', () {
      const artist = Artist(
        name: 'Daft Punk',
        songCount: 25,
        albumCount: 4,
        totalDurationMs: 7200000, // 2 hours
      );

      expect(artist.durationFormatted, '2h 0m');
      expect(artist.albumCount, 4);
      expect(artist.songCount, 25);
    });

    test('Playlist duration and song counts', () {
      const s1 = Song(
        id: '1',
        path: '/a.mp3',
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        durationMs: 120000,
        size: 1000,
        dateAdded: 0,
        dateModified: 0,
        format: 'mp3',
      );
      const s2 = Song(
        id: '2',
        path: '/b.mp3',
        title: 'Song 2',
        artist: 'Artist 2',
        album: 'Album 2',
        durationMs: 180000,
        size: 1000,
        dateAdded: 0,
        dateModified: 0,
        format: 'mp3',
      );

      final playlist = Playlist(
        id: 'pl-1',
        name: 'Workout Mix',
        createdAt: 1000,
        updatedAt: 1000,
        songCount: 2,
        totalDurationMs: 300000,
        songs: const [s1, s2],
      );

      expect(playlist.songCount, 2);
      expect(playlist.durationFormatted, '5m 0s');
    });

    test('ScanResult model properties', () {
      const s = Song(
        id: '1',
        path: '/a.mp3',
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        durationMs: 120000,
        size: 1000,
        dateAdded: 0,
        dateModified: 0,
        format: 'mp3',
      );

      const result = ScanResult(
        totalFilesScanned: 10,
        newSongsAdded: 1,
        newSongs: [s],
      );

      expect(result.totalFilesScanned, 10);
      expect(result.newSongsAdded, 1);
      expect(result.newSongs.length, 1);
      expect(result.newSongs.first.title, 'Song 1');
    });
  });
}
