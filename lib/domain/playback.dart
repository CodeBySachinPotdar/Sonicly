import 'song.dart';

enum CustomRepeatMode {
  off,
  all,
  one,
}

enum SortField {
  title,
  artist,
  album,
  dateAdded,
  duration,
  playCount,
}

enum SortOrder {
  ascending,
  descending,
}

class PlaybackStateModel {
  final Song? currentSong;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final CustomRepeatMode repeatMode;
  final bool isShuffle;
  final List<Song> queue;
  final int currentIndex;

  const PlaybackStateModel({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.repeatMode = CustomRepeatMode.off,
    this.isShuffle = false,
    this.queue = const [],
    this.currentIndex = -1,
  });

  bool get hasCurrentSong => currentSong != null;
  bool get hasNext => queue.isNotEmpty && currentIndex < queue.length - 1;
  bool get hasPrevious => queue.isNotEmpty && currentIndex > 0;

  PlaybackStateModel copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    CustomRepeatMode? repeatMode,
    bool? isShuffle,
    List<Song>? queue,
    int? currentIndex,
  }) {
    return PlaybackStateModel(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffle: isShuffle ?? this.isShuffle,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}
