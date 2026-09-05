import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/audio/queue/queue_manager.dart';
import 'package:music_player/domain/playback.dart';
import 'package:music_player/domain/song.dart';

Song createDummySong(String id, String title) {
  return Song(
    id: id,
    path: '/path/$id.mp3',
    title: title,
    artist: 'Artist',
    album: 'Album',
    durationMs: 180000,
    size: 5000000,
    dateAdded: 0,
    dateModified: 0,
    format: 'mp3',
  );
}

void main() {
  group('QueueManager Tests', () {
    late QueueManager queueManager;
    late List<Song> songs;

    setUp(() {
      queueManager = QueueManager();
      songs = List.generate(5, (i) => createDummySong('$i', 'Track $i'));
    });

    test('Initial queue state', () {
      queueManager.setQueue(songs, initialIndex: 0);

      expect(queueManager.queue.length, 5);
      expect(queueManager.currentIndex, 0);
      expect(queueManager.currentSong?.title, 'Track 0');
      expect(queueManager.hasNext, isTrue);
      expect(queueManager.hasPrevious, isFalse);
    });

    test('Sequential next and previous navigation', () {
      queueManager.setQueue(songs, initialIndex: 0);

      final s1 = queueManager.next();
      expect(s1?.title, 'Track 1');
      expect(queueManager.currentIndex, 1);
      expect(queueManager.hasPrevious, isTrue);

      final s0 = queueManager.previous();
      expect(s0?.title, 'Track 0');
      expect(queueManager.currentIndex, 0);
    });

    test('RepeatMode.all loops around queue ends', () {
      queueManager.setQueue(songs, initialIndex: 4);
      queueManager.setRepeatMode(CustomRepeatMode.all);

      final s0 = queueManager.next();
      expect(s0?.title, 'Track 0');
      expect(queueManager.currentIndex, 0);

      final s4 = queueManager.previous();
      expect(s4?.title, 'Track 4');
      expect(queueManager.currentIndex, 4);
    });

    test('RepeatMode.one returns current song continuously', () {
      queueManager.setQueue(songs, initialIndex: 2);
      queueManager.setRepeatMode(CustomRepeatMode.one);

      final s2 = queueManager.next();
      expect(s2?.title, 'Track 2');
      expect(queueManager.currentIndex, 2);
    });

    test('Shuffle preserves current song and unshuffle restores original sequence', () {
      queueManager.setQueue(songs, initialIndex: 2);
      final currentBeforeShuffle = queueManager.currentSong;

      // Enable shuffle
      final isShuffled = queueManager.toggleShuffle();
      expect(isShuffled, isTrue);
      expect(queueManager.currentSong, currentBeforeShuffle);

      // Disable shuffle
      final isUnshuffled = queueManager.toggleShuffle();
      expect(isUnshuffled, isFalse);
      expect(queueManager.currentSong, currentBeforeShuffle);
      expect(queueManager.queue.map((s) => s.id).toList(), ['0', '1', '2', '3', '4']);
    });

    test('insertNext adds track immediately after current track', () {
      queueManager.setQueue(songs, initialIndex: 1);
      final bonus = createDummySong('bonus', 'Bonus Track');

      queueManager.insertNext(bonus);
      expect(queueManager.queue[2].id, 'bonus');
      expect(queueManager.next()?.title, 'Bonus Track');
    });

    test('reorder updates active queue correctly', () {
      queueManager.setQueue(songs, initialIndex: 0);

      // Move Track 0 to index 2
      queueManager.reorder(0, 2);
      expect(queueManager.queue[2].title, 'Track 0');
      expect(queueManager.currentIndex, 2);
    });

    test('removeAt removes track and adjusts index', () {
      queueManager.setQueue(songs, initialIndex: 2); // 'Track 2'

      // Remove Track 0
      queueManager.removeAt(0);
      expect(queueManager.queue.length, 4);
      expect(queueManager.currentIndex, 1);
      expect(queueManager.currentSong?.title, 'Track 2');
    });
  });
}
