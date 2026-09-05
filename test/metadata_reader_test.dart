import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/data/metadata/audio_metadata_reader.dart';

void main() {
  group('AudioMetadataReader Tests', () {
    test('Gracefully handles non-existent or empty files without throwing', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_empty.mp3');
      await tempFile.writeAsBytes([]);

      final result = await AudioMetadataReader.readMetadata(tempFile);
      expect(result.title, 'test_empty');
      expect(result.artist, 'Unknown Artist');
      expect(result.durationMs, 0);

      await tempFile.delete();
    });

    test('Parses track number, artist, and title from structured filename', () async {
      final tempFile = File('${Directory.systemTemp.path}/05 - Queen - Bohemian Rhapsody.mp3');
      await tempFile.writeAsBytes([0, 0, 0, 0]);

      final result = await AudioMetadataReader.readMetadata(tempFile);
      expect(result.trackNumber, 5);
      expect(result.artist, 'Queen');
      expect(result.title, 'Bohemian Rhapsody');

      await tempFile.delete();
    });

    test('Parses artist and title with dash separator in filename', () async {
      final tempFile = File('${Directory.systemTemp.path}/Daft Punk - One More Time.flac');
      await tempFile.writeAsBytes([0, 0, 0, 0]);

      final result = await AudioMetadataReader.readMetadata(tempFile);
      expect(result.artist, 'Daft Punk');
      expect(result.title, 'One More Time');

      await tempFile.delete();
    });
  });
}
